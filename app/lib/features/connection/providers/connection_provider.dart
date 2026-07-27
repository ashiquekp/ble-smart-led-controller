import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ble_providers.dart';
import '../../../data/ble/ble_command_codec.dart';
import '../../../data/storage/last_device_storage.dart';
import '../../../domain/models/connection_status.dart';
import '../../../domain/models/device_info.dart';
import '../../../domain/repositories/ble_repository.dart';

class ConnectionController extends StateNotifier<ConnectionStatus> {
  ConnectionController(this._repo, this._lastDeviceStorage)
      : super(ConnectionStatus.disconnected) {
    _sub = _repo.connectionStatus.listen((status) {
      state = status;
      if (status == ConnectionStatus.connected && _repo.currentDevice != null) {
        _lastDeviceStorage.save(_repo.currentDevice!);
        _syncDeviceClock();
      }
    });
  }

  final BleRepository _repo;
  final LastDeviceStorage _lastDeviceStorage;
  late final StreamSubscription<ConnectionStatus> _sub;

  DeviceInfo? get currentDevice => _repo.currentDevice;

  /// Scheduling relies on the firmware knowing roughly what time it is
  /// (see Scheduler in firmware/include/scheduler.h) — there's no RTC or
  /// WiFi on the device, so the app is the only source of truth. Sent
  /// once per connection; drift over a very long session is an accepted
  /// trade-off documented alongside the scheduler itself.
  Future<void> _syncDeviceClock() async {
    final now = DateTime.now();
    try {
      await _repo.sendCommand(BleCommandCodec.syncTime(
        hour: now.hour,
        minute: now.minute,
        second: now.second,
        weekday: now.weekday % 7, // Dart: Mon=1..Sun=7 -> 0=Sun..6=Sat
      ));
    } catch (_) {
      // Non-fatal: scheduling just won't be available until the next
      // successful sync (e.g. on reconnect).
    }
  }

  Future<void> connect(DeviceInfo device) async {
    try {
      await _repo.connect(device);
    } catch (_) {
      // Repository already pushed ConnectionStatus.error to the stream;
      // rethrow lets the UI show a snackbar/message if it wants to.
      rethrow;
    }
  }

  Future<void> disconnect() => _repo.disconnect();

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final connectionControllerProvider =
    StateNotifierProvider<ConnectionController, ConnectionStatus>((ref) {
  final repo = ref.watch(bleRepositoryProvider);
  final storage = ref.watch(lastDeviceStorageProvider);
  return ConnectionController(repo, storage);
});

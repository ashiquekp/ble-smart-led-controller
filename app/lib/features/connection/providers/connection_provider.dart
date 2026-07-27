import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ble_providers.dart';
import '../../../data/ble/ble_command_codec.dart';
import '../../../data/storage/history_storage.dart';
import '../../../data/storage/last_device_storage.dart';
import '../../../domain/models/connection_status.dart';
import '../../../domain/models/device_info.dart';
import '../../../domain/models/session_log_entry.dart';
import '../../../domain/repositories/ble_repository.dart';

class ConnectionController extends StateNotifier<ConnectionStatus> {
  ConnectionController(this._repo, this._lastDeviceStorage, this._historyStorage)
      : super(ConnectionStatus.disconnected) {
    _sub = _repo.connectionStatus.listen((status) {
      state = status;

      if (status == ConnectionStatus.connected) {
        // Only start a new session the first time we land on `connected`
        // — a reconnect that recovers mid-session should extend it, not
        // start a fresh one.
        _sessionStart ??= DateTime.now();
        _sessionDeviceName ??= _repo.currentDevice?.name;

        if (_repo.currentDevice != null) {
          _lastDeviceStorage.save(_repo.currentDevice!);
        }
        _syncDeviceClock();
      } else if (status == ConnectionStatus.disconnected ||
          status == ConnectionStatus.error) {
        _closeSessionIfOpen();
      }
    });
  }

  final BleRepository _repo;
  final LastDeviceStorage _lastDeviceStorage;
  final HistoryStorage _historyStorage;
  late final StreamSubscription<ConnectionStatus> _sub;

  DateTime? _sessionStart;
  String? _sessionDeviceName;

  DeviceInfo? get currentDevice => _repo.currentDevice;

  void _closeSessionIfOpen() {
    final start = _sessionStart;
    if (start == null) return;

    _historyStorage.addSession(SessionLogEntry(
      deviceName: _sessionDeviceName ?? 'Unknown device',
      startTime: start,
      endTime: DateTime.now(),
    ));
    _sessionStart = null;
    _sessionDeviceName = null;
  }

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
  final lastDeviceStorage = ref.watch(lastDeviceStorageProvider);
  final historyStorage = ref.watch(historyStorageProvider);
  return ConnectionController(repo, lastDeviceStorage, historyStorage);
});

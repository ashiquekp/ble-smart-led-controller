import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ble_providers.dart';
import '../../../domain/models/connection_status.dart';
import '../../../domain/models/device_info.dart';
import '../../../domain/repositories/ble_repository.dart';

class ConnectionController extends StateNotifier<ConnectionStatus> {
  ConnectionController(this._repo) : super(ConnectionStatus.disconnected) {
    _sub = _repo.connectionStatus.listen((status) => state = status);
  }

  final BleRepository _repo;
  late final StreamSubscription<ConnectionStatus> _sub;

  DeviceInfo? get currentDevice => _repo.currentDevice;

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
  return ConnectionController(repo);
});

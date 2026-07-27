import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../../core/constants/ble_constants.dart';
import '../../domain/models/connection_status.dart';
import '../../domain/models/device_info.dart';
import '../../domain/repositories/ble_repository.dart';

/// [BleRepository] implementation backed by `flutter_blue_plus`.
///
/// This is the ONLY file in the app that imports `flutter_blue_plus`
/// directly. Everything else (providers, screens) talks to
/// [BleRepository], so swapping BLE plugins later touches one file.
class FlutterBluePlusRepository implements BleRepository {
  static const int _maxReconnectAttempts = 3;

  BluetoothDevice? _device;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  StreamSubscription<List<int>>? _statusSub;

  final StreamController<ConnectionStatus> _statusController =
      StreamController<ConnectionStatus>.broadcast();
  final StreamController<List<int>> _notifyController =
      StreamController<List<int>>.broadcast();

  DeviceInfo? _currentDevice;
  BluetoothCharacteristic? _commandChar;
  BluetoothCharacteristic? _statusChar;

  /// True only while a disconnect was explicitly requested via
  /// [disconnect]. Distinguishes "user tapped disconnect" (no retry)
  /// from "link dropped unexpectedly" (auto-reconnect).
  bool _intentionalDisconnect = false;
  int _reconnectAttempts = 0;

  @override
  DeviceInfo? get currentDevice => _currentDevice;

  @override
  Stream<ConnectionStatus> get connectionStatus => _statusController.stream;

  @override
  Stream<List<int>> get statusUpdates => _notifyController.stream;

  @override
  Stream<List<DeviceInfo>> scanForDevices() {
    final controller = StreamController<List<DeviceInfo>>.broadcast();
    final seen = <String, DeviceInfo>{};

    _statusController.add(ConnectionStatus.scanning);

    late final StreamSubscription<List<ScanResult>> resultsSub;
    resultsSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName;
        if (name.isEmpty || !name.contains(BleConstants.deviceNamePrefix)) {
          continue;
        }
        seen[r.device.remoteId.str] = DeviceInfo(
          id: r.device.remoteId.str,
          name: name,
          rssi: r.rssi,
        );
      }
      controller.add(seen.values.toList());
    });

    FlutterBluePlus.startScan(timeout: BleConstants.scanTimeout);

    FlutterBluePlus.isScanning
        .firstWhere((scanning) => scanning == false)
        .then((_) {
      resultsSub.cancel();
      controller.close();
      if (_statusController.hasListener && _currentDevice == null) {
        _statusController.add(ConnectionStatus.disconnected);
      }
    });

    return controller.stream;
  }

  @override
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  @override
  Future<void> connect(DeviceInfo device) async {
    _currentDevice = device;
    _intentionalDisconnect = false;
    _reconnectAttempts = 0;
    await _performConnect(device);
  }

  /// The actual connect + service discovery flow, shared by [connect] and
  /// the internal reconnection loop. Does NOT reset [_reconnectAttempts]
  /// — callers decide when a fresh attempt counter is appropriate.
  Future<void> _performConnect(DeviceInfo device) async {
    _statusController.add(ConnectionStatus.connecting);

    try {
      final bluetoothDevice = BluetoothDevice.fromId(device.id);
      _device = bluetoothDevice;

      await bluetoothDevice.connect(
        timeout: BleConstants.connectionTimeout,
        autoConnect: false,
      );

      _connectionSub?.cancel();
      _connectionSub = bluetoothDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleUnderlyingDisconnect();
        }
      });

      final services = await bluetoothDevice.discoverServices();
      final service = services.firstWhere(
        (s) =>
            s.uuid.str.toLowerCase() == BleConstants.serviceUuid.toLowerCase(),
        orElse: () => throw Exception('Smart LED service not found on device'),
      );

      _commandChar = service.characteristics.firstWhere(
        (c) =>
            c.uuid.str.toLowerCase() ==
            BleConstants.commandCharUuid.toLowerCase(),
      );
      _statusChar = service.characteristics.firstWhere(
        (c) =>
            c.uuid.str.toLowerCase() ==
            BleConstants.statusCharUuid.toLowerCase(),
      );

      await _statusChar!.setNotifyValue(true);
      _statusSub?.cancel();
      _statusSub = _statusChar!.onValueReceived.listen((value) {
        _notifyController.add(value);
      });

      _reconnectAttempts = 0; // link is healthy again
      _statusController.add(ConnectionStatus.connected);
    } catch (e) {
      _statusController.add(ConnectionStatus.error);
      rethrow;
    }
  }

  /// Fired whenever the underlying BLE connection drops, whether the
  /// user asked for it or not.
  void _handleUnderlyingDisconnect() {
    if (_intentionalDisconnect) {
      _cleanupAfterDisconnect();
      _statusController.add(ConnectionStatus.disconnected);
      return;
    }
    _scheduleReconnect();
  }

  /// Retries the connection with exponential backoff (1s, 2s, 4s), up to
  /// [_maxReconnectAttempts] times, before giving up and surfacing an
  /// error. Runs entirely in the background — the UI just watches
  /// [connectionStatus] transition through `reconnecting` and either
  /// lands back on `connected` or ends at `error`.
  Future<void> _scheduleReconnect() async {
    final device = _currentDevice;
    if (device == null) {
      _statusController.add(ConnectionStatus.disconnected);
      return;
    }

    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _cleanupAfterDisconnect(keepCurrentDevice: true);
      _statusController.add(ConnectionStatus.error);
      return;
    }

    _reconnectAttempts++;
    _statusController.add(ConnectionStatus.reconnecting);

    final backoff = Duration(seconds: 1 << (_reconnectAttempts - 1)); // 1,2,4
    await Future.delayed(backoff);

    // Another disconnect/connect cycle may have superseded this attempt.
    if (_currentDevice?.id != device.id) return;

    try {
      await _performConnect(device);
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _cleanupAfterDisconnect({bool keepCurrentDevice = false}) {
    _connectionSub?.cancel();
    _statusSub?.cancel();
    _commandChar = null;
    _statusChar = null;
    if (!keepCurrentDevice) {
      _currentDevice = null;
    }
  }

  @override
  Future<void> disconnect() async {
    _intentionalDisconnect = true;
    await _device?.disconnect();
    _cleanupAfterDisconnect();
    _currentDevice = null;
    _statusController.add(ConnectionStatus.disconnected);
  }

  @override
  Future<void> sendCommand(List<int> packet) async {
    if (_commandChar == null) {
      throw StateError('Cannot send command: not connected to a device');
    }
    await _commandChar!.write(packet, withoutResponse: true);
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _statusSub?.cancel();
    _statusController.close();
    _notifyController.close();
  }
}

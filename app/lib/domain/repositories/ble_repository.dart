import '../models/connection_status.dart';
import '../models/device_info.dart';

/// Contract for BLE operations. Features depend on this abstraction, not
/// on `flutter_blue_plus` directly — so the whole app is testable with a
/// fake/mock implementation and the underlying BLE plugin is swappable.
abstract class BleRepository {
  /// Stream of devices found during an active scan. Emits a growing list
  /// (deduped by id) for the duration of the scan.
  Stream<List<DeviceInfo>> scanForDevices();

  Future<void> stopScan();

  Future<void> connect(DeviceInfo device);

  Future<void> disconnect();

  /// Current connection lifecycle state.
  Stream<ConnectionStatus> get connectionStatus;

  /// The device currently connected (or being connected to), if any.
  DeviceInfo? get currentDevice;

  /// Raw status packet notifications from the Status characteristic.
  /// Decoded by higher layers (introduced in Phase 2) into device state.
  Stream<List<int>> get statusUpdates;

  /// Sends a raw, already-encoded command packet to the Command
  /// characteristic. Encoding lives in `BleCommandCodec` (Phase 2+).
  Future<void> sendCommand(List<int> packet);

  void dispose();
}

/// Custom BLE Smart LED Service UUIDs.
///
/// These MUST match `firmware/include/config.h` exactly, since the app
/// and firmware are two independent halves of one wire protocol.
/// See docs/ARCHITECTURE.md for the full GATT design and opcode table.
class BleConstants {
  BleConstants._();

  static const String serviceUuid = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
  static const String commandCharUuid = '6e400002-b5a3-f393-e0a9-e50e24dcca9e';
  static const String statusCharUuid = '6e400003-b5a3-f393-e0a9-e50e24dcca9e';

  /// Prefix used to identify our devices during scanning, before the
  /// user has paired/saved one. Matches DEVICE_NAME in firmware config.h.
  static const String deviceNamePrefix = 'SmartLED';

  static const Duration scanTimeout = Duration(seconds: 8);
  static const Duration connectionTimeout = Duration(seconds: 10);
}

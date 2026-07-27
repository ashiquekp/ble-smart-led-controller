/// Encodes app-level commands into the fixed binary packet format the
/// firmware expects: [opcode][payload_len][payload...][xor_checksum].
///
/// Keeping ALL encoding in one place means the wire format is defined
/// exactly once on the app side — no feature reaches into raw bytes
/// itself. See docs/ARCHITECTURE.md for the opcode table (must match
/// `firmware/include/config.h`).
class BleCommandCodec {
  BleCommandCodec._();

  static const int opSetPower = 0x01;
  static const int opSetColor = 0x02;
  static const int opSetBrightness = 0x03;
  static const int opSetEffect = 0x04;
  static const int opSetSpeed = 0x05;
  static const int opSetSchedule = 0x06;
  static const int opRequestStatus = 0x07;

  static List<int> _build(int opcode, List<int> payload) {
    final packet = <int>[opcode, payload.length, ...payload];
    var checksum = 0;
    for (final b in packet) {
      checksum ^= b;
    }
    packet.add(checksum);
    return packet;
  }

  static List<int> setPower(bool on) => _build(opSetPower, [on ? 1 : 0]);

  static List<int> setColor(int r, int g, int b) =>
      _build(opSetColor, [r & 0xFF, g & 0xFF, b & 0xFF]);

  static List<int> setBrightness(int brightness) =>
      _build(opSetBrightness, [brightness & 0xFF]);

  static List<int> setEffect(int effectId) =>
      _build(opSetEffect, [effectId & 0xFF]);

  static List<int> setSpeed(int speed) => _build(opSetSpeed, [speed & 0xFF]);

  static List<int> setSchedule({
    required int action,
    required int hour,
    required int minute,
    required int repeatMask,
  }) =>
      _build(opSetSchedule, [action, hour, minute, repeatMask]);

  static List<int> requestStatus() => _build(opRequestStatus, const []);

  /// Decodes a Status characteristic notify payload:
  /// [power, r, g, b, brightness, effectId, speed, errorCode]
  static DecodedStatus? decodeStatus(List<int> data) {
    if (data.length < 8) return null;
    return DecodedStatus(
      power: data[0] != 0,
      r: data[1],
      g: data[2],
      b: data[3],
      brightness: data[4],
      effectId: data[5],
      speed: data[6],
      errorCode: data[7],
    );
  }
}

class DecodedStatus {
  final bool power;
  final int r, g, b;
  final int brightness;
  final int effectId;
  final int speed;
  final int errorCode;

  const DecodedStatus({
    required this.power,
    required this.r,
    required this.g,
    required this.b,
    required this.brightness,
    required this.effectId,
    required this.speed,
    required this.errorCode,
  });
}

import 'package:equatable/equatable.dart';

/// Mirrors the firmware's `DeviceState` — kept as a plain data class so
/// the control UI has one source of truth to read from, whether the
/// value came from a local optimistic update or a Status notify.
class LedControlState extends Equatable {
  final bool power;
  final int r;
  final int g;
  final int b;
  final int brightness; // 0-255
  final int effectId; // 0 = solid color (Phase 3 adds more)
  final int speed; // 0-255, meaningful once effects exist

  const LedControlState({
    this.power = true,
    this.r = 255,
    this.g = 255,
    this.b = 255,
    this.brightness = 128,
    this.effectId = 0,
    this.speed = 128,
  });

  LedControlState copyWith({
    bool? power,
    int? r,
    int? g,
    int? b,
    int? brightness,
    int? effectId,
    int? speed,
  }) {
    return LedControlState(
      power: power ?? this.power,
      r: r ?? this.r,
      g: g ?? this.g,
      b: b ?? this.b,
      brightness: brightness ?? this.brightness,
      effectId: effectId ?? this.effectId,
      speed: speed ?? this.speed,
    );
  }

  @override
  List<Object?> get props => [power, r, g, b, brightness, effectId, speed];
}

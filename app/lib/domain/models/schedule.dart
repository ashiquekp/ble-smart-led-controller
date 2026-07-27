import 'package:equatable/equatable.dart';

/// Mirrors `ScheduleAction` in firmware/include/scheduler.h.
enum ScheduleAction { off, on }

extension ScheduleActionWire on ScheduleAction {
  int get wireValue => this == ScheduleAction.on ? 1 : 0;
}

/// A single on/off schedule slot. The firmware currently supports one
/// active schedule at a time — see docs/ARCHITECTURE.md for why (the
/// wire protocol supports extending this to multiple slots later
/// without a breaking change, by adding a slot-index byte).
class Schedule extends Equatable {
  final bool enabled;
  final ScheduleAction action;
  final int hour; // 0-23
  final int minute; // 0-59

  /// Days this repeats on: 0 = Sunday ... 6 = Saturday. Empty set means
  /// "one-shot" — fires once, then the firmware disables it.
  final Set<int> repeatDays;

  const Schedule({
    this.enabled = false,
    this.action = ScheduleAction.off,
    this.hour = 22,
    this.minute = 0,
    this.repeatDays = const {},
  });

  int get repeatMask =>
      repeatDays.fold(0, (mask, day) => mask | (1 << day));

  String get timeLabel {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Schedule copyWith({
    bool? enabled,
    ScheduleAction? action,
    int? hour,
    int? minute,
    Set<int>? repeatDays,
  }) {
    return Schedule(
      enabled: enabled ?? this.enabled,
      action: action ?? this.action,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      repeatDays: repeatDays ?? this.repeatDays,
    );
  }

  @override
  List<Object?> get props => [enabled, action, hour, minute, repeatDays];
}

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ble_providers.dart';
import '../../../data/ble/ble_command_codec.dart';
import '../../../domain/models/schedule.dart';
import '../../../domain/repositories/ble_repository.dart';

/// Matches `SCHEDULE_ACTION_CLEAR` in firmware/include/scheduler.h — not
/// part of [ScheduleAction] since "clear" isn't a firing behavior, it's
/// a control command.
const int _scheduleActionClear = 2;

class SchedulingController extends StateNotifier<Schedule> {
  SchedulingController(this._repo) : super(const Schedule());

  final BleRepository _repo;

  void setAction(ScheduleAction action) {
    state = state.copyWith(action: action);
  }

  void setTime(int hour, int minute) {
    state = state.copyWith(hour: hour, minute: minute);
  }

  void toggleDay(int day) {
    final days = Set<int>.from(state.repeatDays);
    if (days.contains(day)) {
      days.remove(day);
    } else {
      days.add(day);
    }
    state = state.copyWith(repeatDays: days);
  }

  /// Sends the current schedule to the device and marks it enabled.
  Future<void> apply() async {
    state = state.copyWith(enabled: true);
    await _repo.sendCommand(BleCommandCodec.setSchedule(
      action: state.action.wireValue,
      hour: state.hour,
      minute: state.minute,
      repeatMask: state.repeatMask,
    ));
  }

  /// Cancels the active schedule on the device.
  Future<void> clear() async {
    state = state.copyWith(enabled: false);
    await _repo.sendCommand(BleCommandCodec.setSchedule(
      action: _scheduleActionClear,
      hour: 0,
      minute: 0,
      repeatMask: 0,
    ));
  }
}

final schedulingControllerProvider =
    StateNotifierProvider<SchedulingController, Schedule>((ref) {
  final repo = ref.watch(bleRepositoryProvider);
  return SchedulingController(repo);
});

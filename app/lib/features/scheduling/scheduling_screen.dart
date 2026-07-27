import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/schedule.dart';
import 'providers/scheduling_provider.dart';
import 'widgets/repeat_day_selector.dart';
import 'widgets/schedule_action_and_time.dart';

class SchedulingScreen extends ConsumerWidget {
  const SchedulingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedule = ref.watch(schedulingControllerProvider);
    final controller = ref.read(schedulingControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Schedule')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (schedule.enabled)
            Card(
              color: Colors.greenAccent.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.greenAccent),
                title: Text(
                  'Active: ${schedule.action == ScheduleAction.on ? 'Turn on' : 'Turn off'} '
                  'at ${schedule.timeLabel}'
                  '${schedule.repeatDays.isEmpty ? ' (once)' : ' (repeats)'}',
                ),
              ),
            ),
          const SizedBox(height: 4),
          ScheduleActionAndTime(
            action: schedule.action,
            hour: schedule.hour,
            minute: schedule.minute,
            onActionChanged: controller.setAction,
            onTimeChanged: (time) => controller.setTime(time.hour, time.minute),
          ),
          const SizedBox(height: 12),
          RepeatDaySelector(
            selectedDays: schedule.repeatDays,
            onToggle: controller.toggleDay,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: controller.apply,
                  icon: const Icon(Icons.check),
                  label: const Text('Save schedule'),
                ),
              ),
              if (schedule.enabled) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close),
                  label: const Text('Clear'),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'The device keeps its own clock synced from your phone each '
            'time you connect. Only one schedule can be active at a time.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

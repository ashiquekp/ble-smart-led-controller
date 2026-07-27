import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/schedule.dart';

class ScheduleActionAndTime extends StatelessWidget {
  final ScheduleAction action;
  final int hour;
  final int minute;
  final ValueChanged<ScheduleAction> onActionChanged;
  final ValueChanged<TimeOfDay> onTimeChanged;

  const ScheduleActionAndTime({
    super.key,
    required this.action,
    required this.hour,
    required this.minute,
    required this.onActionChanged,
    required this.onTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Action', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            SegmentedButton<ScheduleAction>(
              segments: const [
                ButtonSegment(
                  value: ScheduleAction.on,
                  label: Text('Turn on'),
                  icon: Icon(Icons.lightbulb),
                ),
                ButtonSegment(
                  value: ScheduleAction.off,
                  label: Text('Turn off'),
                  icon: Icon(Icons.lightbulb_outline),
                ),
              ],
              selected: {action},
              onSelectionChanged: (selection) => onActionChanged(selection.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 20),
            const Text('At', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay(hour: hour, minute: minute),
                );
                if (picked != null) onTimeChanged(picked);
              },
              icon: const Icon(Icons.access_time),
              label: Text(
                TimeOfDay(hour: hour, minute: minute).format(context),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

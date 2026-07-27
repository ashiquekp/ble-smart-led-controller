import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class RepeatDaySelector extends StatelessWidget {
  final Set<int> selectedDays; // 0 = Sunday ... 6 = Saturday
  final ValueChanged<int> onToggle;

  const RepeatDaySelector({
    super.key,
    required this.selectedDays,
    required this.onToggle,
  });

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Repeat', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              selectedDays.isEmpty
                  ? 'One time only'
                  : 'Repeats weekly on selected days',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (day) {
                final selected = selectedDays.contains(day);
                return InkWell(
                  onTap: () => onToggle(day),
                  customBorder: const CircleBorder(),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor:
                        selected ? AppTheme.accent : AppTheme.surfaceVariant,
                    child: Text(
                      _labels[day],
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

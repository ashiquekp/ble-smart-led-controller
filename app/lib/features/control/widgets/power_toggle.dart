import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class PowerToggle extends StatelessWidget {
  final bool power;
  final ValueChanged<bool> onChanged;

  const PowerToggle({super.key, required this.power, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Row(
          children: [
            Icon(
              power ? Icons.lightbulb : Icons.lightbulb_outline,
              color: power ? AppTheme.accent : Colors.white38,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                power ? 'Strip is on' : 'Strip is off',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            Switch(
              value: power,
              onChanged: onChanged,
              activeColor: AppTheme.accent,
            ),
          ],
        ),
      ),
    );
  }
}

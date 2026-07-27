import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class BrightnessSlider extends StatelessWidget {
  final int brightness; // 0-255
  final ValueChanged<int> onChanged;

  const BrightnessSlider({
    super.key,
    required this.brightness,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final percent = ((brightness / 255) * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Brightness', style: TextStyle(fontWeight: FontWeight.w600)),
                Text('$percent%', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            Slider(
              value: brightness.toDouble(),
              min: 0,
              max: 255,
              activeColor: AppTheme.accent,
              onChanged: (value) => onChanged(value.round()),
            ),
          ],
        ),
      ),
    );
  }
}

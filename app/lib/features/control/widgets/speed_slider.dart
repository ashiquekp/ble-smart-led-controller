import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class SpeedSlider extends StatelessWidget {
  final int speed; // 0-255
  final bool enabled;
  final ValueChanged<int> onChanged;

  const SpeedSlider({
    super.key,
    required this.speed,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Speed', style: TextStyle(fontWeight: FontWeight.w600)),
                  Icon(Icons.speed, color: Colors.white54, size: 18),
                ],
              ),
              Slider(
                value: speed.toDouble(),
                min: 0,
                max: 255,
                activeColor: AppTheme.accent,
                onChanged: enabled ? (value) => onChanged(value.round()) : null,
              ),
              if (!enabled)
                const Text(
                  'Select an animated effect to control speed',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

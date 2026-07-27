import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorWheelSection extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorWheelSection({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Color', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 8),
            ColorPicker(
              pickerColor: color,
              onColorChanged: onColorChanged,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hueWheel,
              pickerAreaHeightPercent: 0.65,
              labelTypes: const [],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/led_effect.dart';

class EffectPicker extends StatelessWidget {
  final int selectedEffectId;
  final ValueChanged<int> onSelected;

  const EffectPicker({
    super.key,
    required this.selectedEffectId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Effect', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: LedEffect.all.map((effect) {
                final selected = effect.id == selectedEffectId;
                return ChoiceChip(
                  label: Text(effect.label),
                  selected: selected,
                  selectedColor: AppTheme.accent,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.white70,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  backgroundColor: AppTheme.surfaceVariant,
                  onSelected: (_) => onSelected(effect.id),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              LedEffect.byId(selectedEffectId).description,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mirrors `EffectId` in `firmware/include/effects_engine.h`. Keep the
/// ids in sync — they're sent over BLE as raw bytes, not names.
class LedEffect {
  final int id;
  final String label;
  final String description;

  const LedEffect({
    required this.id,
    required this.label,
    required this.description,
  });

  static const solid = LedEffect(
    id: 0,
    label: 'Solid',
    description: 'A single steady color',
  );
  static const rainbow = LedEffect(
    id: 1,
    label: 'Rainbow',
    description: 'Smooth color cycle across the strip',
  );
  static const breathing = LedEffect(
    id: 2,
    label: 'Breathing',
    description: 'Gentle fade in and out',
  );
  static const chase = LedEffect(
    id: 3,
    label: 'Chase',
    description: 'A moving pixel with a fading trail',
  );
  static const fire = LedEffect(
    id: 4,
    label: 'Fire',
    description: 'Flickering flame simulation',
  );

  static const all = [solid, rainbow, breathing, chase, fire];

  static LedEffect byId(int id) => all.firstWhere(
        (e) => e.id == id,
        orElse: () => solid,
      );
}

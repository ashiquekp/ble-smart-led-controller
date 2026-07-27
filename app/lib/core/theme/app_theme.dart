import 'package:flutter/material.dart';

/// A dark theme suits a lighting-control app: it makes color previews and
/// LED swatches pop, and it matches the visual language of Hue/Govee.
class AppTheme {
  AppTheme._();

  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF1A1D23);
  static const Color surfaceVariant = Color(0xFF242830);
  static const Color accent = Color(0xFF7C5CFF);
  static const Color connectedGreen = Color(0xFF3DDC84);
  static const Color errorRed = Color(0xFFFF5B5B);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: surface,
        error: errorRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textTheme: base.textTheme.apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
    );
  }
}

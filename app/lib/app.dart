import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/scanning/scan_screen.dart';

class BleSmartLedApp extends StatelessWidget {
  const BleSmartLedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GlowLink',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const ScanScreen(),
    );
  }
}

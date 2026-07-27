import 'dart:async';
import 'dart:ui' show Color;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../connection/providers/connection_provider.dart';
import '../../domain/models/connection_status.dart';
import 'providers/led_control_provider.dart';
import 'widgets/brightness_slider.dart';
import 'widgets/color_wheel_section.dart';
import 'widgets/effect_picker.dart';
import 'widgets/power_toggle.dart';
import 'widgets/speed_slider.dart';

class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({super.key});

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  Timer? _colorSendDebounce;

  @override
  void dispose() {
    _colorSendDebounce?.cancel();
    super.dispose();
  }

  void _onColorChanged(Color color) {
    final controller = ref.read(ledControlControllerProvider.notifier);
    final r = color.red;
    final g = color.green;
    final b = color.blue;

    // Instant local feedback so the wheel never feels laggy...
    controller.previewColor(r, g, b);

    // ...but the actual BLE write is debounced so a drag gesture doesn't
    // flood the link with a command per pixel.
    _colorSendDebounce?.cancel();
    _colorSendDebounce = Timer(const Duration(milliseconds: 80), () {
      controller.sendColor(r, g, b);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ledState = ref.watch(ledControlControllerProvider);
    final controller = ref.read(ledControlControllerProvider.notifier);

    ref.listen<ConnectionStatus>(connectionControllerProvider, (previous, next) {
      if (next == ConnectionStatus.disconnected) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lighting control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            tooltip: 'Disconnect',
            onPressed: () =>
                ref.read(connectionControllerProvider.notifier).disconnect(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PowerToggle(
            power: ledState.power,
            onChanged: controller.setPower,
          ),
          const SizedBox(height: 12),
          EffectPicker(
            selectedEffectId: ledState.effectId,
            onSelected: controller.setEffect,
          ),
          const SizedBox(height: 12),
          ColorWheelSection(
            color: Color.fromARGB(255, ledState.r, ledState.g, ledState.b),
            onColorChanged: _onColorChanged,
          ),
          const SizedBox(height: 12),
          SpeedSlider(
            speed: ledState.speed,
            enabled: ledState.effectId != 0,
            onChanged: controller.setSpeed,
          ),
          const SizedBox(height: 12),
          BrightnessSlider(
            brightness: ledState.brightness,
            onChanged: controller.setBrightness,
          ),
        ],
      ),
    );
  }
}

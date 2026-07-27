import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/device_info.dart';

/// Minimal local persistence: just "the last device we successfully
/// connected to". Deliberately not a full favorites/presets store — see
/// docs/ARCHITECTURE.md for why persistence scope was kept minimal in v1.
class LastDeviceStorage {
  static const _key = 'last_connected_device';

  Future<void> save(DeviceInfo device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(device.toJson()));
  }

  Future<DeviceInfo?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      return DeviceInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Corrupt/old-format value — treat as "no saved device" rather than crash.
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

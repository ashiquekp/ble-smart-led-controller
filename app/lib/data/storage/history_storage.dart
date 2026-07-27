import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/session_log_entry.dart';

/// Persists a rolling log of BLE sessions. Capped at [_maxEntries] so a
/// long-lived install doesn't grow this indefinitely — old entries are
/// dropped, newest first.
class HistoryStorage {
  static const _key = 'session_history';
  static const _maxEntries = 50;

  Future<List<SessionLogEntry>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SessionLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt/old-format value — treat as empty history rather than crash.
      return [];
    }
  }

  Future<void> addSession(SessionLogEntry entry) async {
    final existing = await load();
    final updated = [entry, ...existing].take(_maxEntries).toList();
    await _save(updated);
  }

  Future<void> clear() async {
    await _save(const []);
  }

  Future<void> _save(List<SessionLogEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}

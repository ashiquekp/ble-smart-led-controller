import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ble_providers.dart';
import '../../../domain/models/session_log_entry.dart';

/// Full session history, newest first. `autoDispose` + re-created on
/// each visit to the history screen so it always reflects the latest
/// saved sessions without needing a separate reactive store.
final historyListProvider =
    FutureProvider.autoDispose<List<SessionLogEntry>>((ref) {
  final storage = ref.watch(historyStorageProvider);
  return storage.load();
});

class HistoryStats {
  final int sessionCount;
  final Duration totalConnectedTime;
  final Duration averageSessionLength;

  const HistoryStats({
    required this.sessionCount,
    required this.totalConnectedTime,
    required this.averageSessionLength,
  });

  factory HistoryStats.fromEntries(List<SessionLogEntry> entries) {
    if (entries.isEmpty) {
      return const HistoryStats(
        sessionCount: 0,
        totalConnectedTime: Duration.zero,
        averageSessionLength: Duration.zero,
      );
    }
    final total = entries.fold<Duration>(
      Duration.zero,
      (sum, e) => sum + e.duration,
    );
    return HistoryStats(
      sessionCount: entries.length,
      totalConnectedTime: total,
      averageSessionLength: total ~/ entries.length,
    );
  }
}

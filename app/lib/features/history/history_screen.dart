import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/ble_providers.dart';
import 'providers/history_provider.dart';
import 'widgets/history_stats_card.dart';
import 'widgets/session_tile.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This removes all saved sessions. This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(historyStorageProvider).clear();
      ref.invalidate(historyListProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session history'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear history',
            onPressed: () => _confirmClear(context, ref),
          ),
        ],
      ),
      body: history.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const _EmptyHistory();
          }
          final stats = HistoryStats.fromEntries(entries);
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HistoryStatsCard(stats: stats),
              ),
              const SizedBox(height: 12),
              ...entries.map((e) => SessionTile(session: e)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Could not load history: $error')),
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 48, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'No sessions yet.\nConnect to your strip to start building history.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

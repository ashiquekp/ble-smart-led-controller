import 'package:flutter/material.dart';

import '../providers/history_provider.dart';

class HistoryStatsCard extends StatelessWidget {
  final HistoryStats stats;

  const HistoryStatsCard({super.key, required this.stats});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours == 0 && minutes == 0) return '<1m';
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatColumn(label: 'Sessions', value: '${stats.sessionCount}'),
            _StatColumn(
              label: 'Total time',
              value: _formatDuration(stats.totalConnectedTime),
            ),
            _StatColumn(
              label: 'Avg session',
              value: _formatDuration(stats.averageSessionLength),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }
}

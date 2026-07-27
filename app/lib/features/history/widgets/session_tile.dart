import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/session_log_entry.dart';

class SessionTile extends StatelessWidget {
  final SessionLogEntry session;

  const SessionTile({super.key, required this.session});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (isToday) return 'Today, $time';
    return '${dt.month}/${dt.day}, $time';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.surfaceVariant,
          child: Icon(Icons.bluetooth_connected, color: AppTheme.accent, size: 20),
        ),
        title: Text(session.deviceName),
        subtitle: Text(_formatDate(session.startTime)),
        trailing: Text(
          _formatDuration(session.duration),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

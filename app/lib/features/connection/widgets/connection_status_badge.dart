import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/connection_status.dart';

class ConnectionStatusBadge extends StatelessWidget {
  final ConnectionStatus status;

  const ConnectionStatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case ConnectionStatus.connected:
        return AppTheme.connectedGreen;
      case ConnectionStatus.error:
        return AppTheme.errorRed;
      case ConnectionStatus.connecting:
      case ConnectionStatus.reconnecting:
      case ConnectionStatus.scanning:
        return Colors.amber;
      case ConnectionStatus.disconnected:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _color, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status.isBusy)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: _color),
            )
          else
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(color: _color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

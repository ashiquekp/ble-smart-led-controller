import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/device_info.dart';

class LastDeviceBanner extends StatelessWidget {
  final DeviceInfo device;
  final bool isConnecting;
  final VoidCallback onReconnect;

  const LastDeviceBanner({
    super.key,
    required this.device,
    required this.onReconnect,
    this.isConnecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      color: AppTheme.surfaceVariant,
      child: ListTile(
        leading: const Icon(Icons.history, color: AppTheme.accent),
        title: Text('Last used: ${device.name}'),
        subtitle: const Text('Tap to reconnect'),
        trailing: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.chevron_right),
        onTap: isConnecting ? null : onReconnect,
      ),
    );
  }
}

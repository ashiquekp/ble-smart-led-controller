import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/models/device_info.dart';

class DeviceTile extends StatelessWidget {
  final DeviceInfo device;
  final VoidCallback onTap;
  final bool isConnecting;

  const DeviceTile({
    super.key,
    required this.device,
    required this.onTap,
    this.isConnecting = false,
  });

  IconData get _signalIcon {
    if (device.rssi >= -60) return Icons.wifi;
    if (device.rssi >= -80) return Icons.wifi_2_bar;
    return Icons.wifi_1_bar;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppTheme.surfaceVariant,
          child: Icon(Icons.lightbulb_outline, color: AppTheme.accent),
        ),
        title: Text(
          device.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('${device.rssi} dBm', style: const TextStyle(fontSize: 12)),
        trailing: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_signalIcon, color: Colors.white54),
        onTap: isConnecting ? null : onTap,
      ),
    );
  }
}

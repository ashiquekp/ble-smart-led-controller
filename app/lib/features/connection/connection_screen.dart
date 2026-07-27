import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/connection_status.dart';
import 'providers/connection_provider.dart';
import 'widgets/connection_status_badge.dart';

class ConnectionScreen extends ConsumerWidget {
  const ConnectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionControllerProvider);
    final device = ref.read(connectionControllerProvider.notifier).currentDevice;

    ref.listen<ConnectionStatus>(connectionControllerProvider, (previous, next) {
      if (next == ConnectionStatus.disconnected && previous == ConnectionStatus.connected) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(device?.name ?? 'Device')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lightbulb, size: 72, color: Colors.amber),
              const SizedBox(height: 20),
              Text(
                device?.name ?? 'Unknown device',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              ConnectionStatusBadge(status: status),
              const SizedBox(height: 40),
              if (status == ConnectionStatus.connected)
                const _ControlPlaceholder()
              else if (status == ConnectionStatus.error)
                Text(
                  'Something went wrong connecting to this device.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 40),
              OutlinedButton.icon(
                onPressed: () =>
                    ref.read(connectionControllerProvider.notifier).disconnect(),
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('Disconnect'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phase 1 only proves the BLE link works end-to-end. The real color /
/// brightness / effects dashboard is built in Phase 2 and 3.
class _ControlPlaceholder extends StatelessWidget {
  const _ControlPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: const [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 32),
            SizedBox(height: 12),
            Text(
              'BLE link established.\nColor and effects controls arrive in Phase 2.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

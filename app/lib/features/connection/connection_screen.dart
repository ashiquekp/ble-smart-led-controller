import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/connection_status.dart';
import '../control/control_screen.dart';
import 'providers/connection_provider.dart';
import 'widgets/connection_status_badge.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({super.key});

  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  bool _navigatedToControls = false;

  void _handleStatus(ConnectionStatus status) {
    if (status == ConnectionStatus.connected && !_navigatedToControls) {
      _navigatedToControls = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ControlScreen()),
        );
      });
    } else if (status == ConnectionStatus.disconnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // ref.listen (in build) only fires on FUTURE state changes. If the
    // connection already finished before this screen mounted — which is
    // the common case, since ScanScreen awaits connect() before pushing
    // here — there's no new transition to catch, and without this check
    // we'd sit on this screen forever despite already being connected.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleStatus(ref.read(connectionControllerProvider));
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(connectionControllerProvider);
    final device = ref.read(connectionControllerProvider.notifier).currentDevice;

    // Still needed for transitions that happen WHILE this screen is
    // already open and watching — e.g. reconnecting -> connected.
    ref.listen<ConnectionStatus>(connectionControllerProvider, (previous, next) {
      _handleStatus(next);
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
              if (status == ConnectionStatus.error)
                Text(
                  'Lost the connection and couldn\'t reconnect automatically.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                )
              else if (status == ConnectionStatus.reconnecting)
                const Text(
                  'Connection dropped — trying to reconnect...',
                  style: TextStyle(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (status == ConnectionStatus.error && device != null) ...[
                    ElevatedButton.icon(
                      onPressed: () =>
                          ref.read(connectionControllerProvider.notifier).connect(device),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(connectionControllerProvider.notifier).disconnect(),
                    icon: const Icon(Icons.bluetooth_disabled),
                    label: const Text('Disconnect'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


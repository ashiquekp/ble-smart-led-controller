import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/device_info.dart';
import '../../connection/connection_screen.dart';
import '../../connection/providers/connection_provider.dart';
import '../providers/scan_providers.dart';
import 'widgets/device_tile.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  String? _connectingDeviceId;

  Future<void> _connect(DeviceInfo device) async {
    setState(() => _connectingDeviceId = device.id);
    try {
      await ref.read(connectionControllerProvider.notifier).connect(device);
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ConnectionScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not connect: $e')),
      );
    } finally {
      if (mounted) setState(() => _connectingDeviceId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanResults = ref.watch(scanResultsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Find your LED strip')),
      body: scanResults.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const _ScanEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final device = devices[index];
              return DeviceTile(
                device: device,
                isConnecting: _connectingDeviceId == device.id,
                onTap: () => _connect(device),
              );
            },
          );
        },
        loading: () => const _ScanEmptyState(scanning: true),
        error: (error, _) => Center(
          child: Text('Scan failed: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.refresh(scanResultsProvider),
        icon: const Icon(Icons.refresh),
        label: const Text('Rescan'),
      ),
    );
  }
}

class _ScanEmptyState extends StatelessWidget {
  final bool scanning;
  const _ScanEmptyState({this.scanning = false});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (scanning)
            const CircularProgressIndicator()
          else
            const Icon(Icons.bluetooth_searching, size: 48, color: Colors.white38),
          const SizedBox(height: 16),
          Text(
            scanning ? 'Scanning for devices...' : 'No Smart LED devices found nearby',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

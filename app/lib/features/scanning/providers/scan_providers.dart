import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ble_providers.dart';
import '../../../domain/models/device_info.dart';

/// Live list of nearby Smart LED devices while a scan is active.
///
/// `autoDispose` so the scan stops (repository stream is cancelled via
/// its own timeout) once the scan screen is no longer being watched.
final scanResultsProvider =
    StreamProvider.autoDispose<List<DeviceInfo>>((ref) {
  final repo = ref.watch(bleRepositoryProvider);
  return repo.scanForDevices();
});

/// The last device the app successfully connected to, if any — lets the
/// scan screen offer a one-tap "reconnect" shortcut instead of making
/// the user find it in the scan list again.
final lastDeviceProvider = FutureProvider.autoDispose<DeviceInfo?>((ref) {
  final storage = ref.watch(lastDeviceStorageProvider);
  return storage.load();
});

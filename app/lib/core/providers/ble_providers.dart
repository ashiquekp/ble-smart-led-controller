import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ble/flutter_blue_plus_repository.dart';
import '../../data/storage/history_storage.dart';
import '../../data/storage/last_device_storage.dart';
import '../../domain/repositories/ble_repository.dart';

/// The single [BleRepository] instance for the app's lifetime.
///
/// Kept as a plain [Provider] (not overridden per-feature) so every
/// feature shares one real BLE connection — you can't have two parts of
/// the UI independently "connected" to different states.
final bleRepositoryProvider = Provider<BleRepository>((ref) {
  final repo = FlutterBluePlusRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

final lastDeviceStorageProvider = Provider<LastDeviceStorage>((ref) {
  return LastDeviceStorage();
});

final historyStorageProvider = Provider<HistoryStorage>((ref) {
  return HistoryStorage();
});

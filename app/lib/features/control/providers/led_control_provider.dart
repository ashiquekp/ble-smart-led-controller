import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/ble_providers.dart';
import '../../../data/ble/ble_command_codec.dart';
import '../../../domain/models/led_control_state.dart';
import '../../../domain/repositories/ble_repository.dart';

class LedControlController extends StateNotifier<LedControlState> {
  LedControlController(this._repo) : super(const LedControlState()) {
    _statusSub = _repo.statusUpdates.listen(_onStatusNotify);
  }

  final BleRepository _repo;
  late final StreamSubscription<List<int>> _statusSub;

  void _onStatusNotify(List<int> raw) {
    final decoded = BleCommandCodec.decodeStatus(raw);
    if (decoded == null) return;
    state = state.copyWith(
      power: decoded.power,
      r: decoded.r,
      g: decoded.g,
      b: decoded.b,
      brightness: decoded.brightness,
      effectId: decoded.effectId,
      speed: decoded.speed,
    );
  }

  /// Optimistically updates local state, then sends the command. If the
  /// write fails, the next Status notify (or a manual refresh) is what
  /// corrects the UI — we don't roll back automatically, since a failed
  /// BLE write on a slider drag would cause visible flicker.
  Future<void> setColor(int r, int g, int b) async {
    state = state.copyWith(r: r, g: g, b: b);
    await _repo.sendCommand(BleCommandCodec.setColor(r, g, b));
  }

  /// Updates local UI state only — no BLE write. Used by the color wheel
  /// so dragging feels instant; the caller debounces [sendColor] on top.
  void previewColor(int r, int g, int b) {
    state = state.copyWith(r: r, g: g, b: b);
  }

  Future<void> sendColor(int r, int g, int b) async {
    await _repo.sendCommand(BleCommandCodec.setColor(r, g, b));
  }

  Future<void> setBrightness(int brightness) async {
    state = state.copyWith(brightness: brightness);
    await _repo.sendCommand(BleCommandCodec.setBrightness(brightness));
  }

  Future<void> setPower(bool on) async {
    state = state.copyWith(power: on);
    await _repo.sendCommand(BleCommandCodec.setPower(on));
  }

  Future<void> setEffect(int effectId) async {
    state = state.copyWith(effectId: effectId);
    await _repo.sendCommand(BleCommandCodec.setEffect(effectId));
  }

  Future<void> setSpeed(int speed) async {
    state = state.copyWith(speed: speed);
    await _repo.sendCommand(BleCommandCodec.setSpeed(speed));
  }

  Future<void> requestStatus() async {
    await _repo.sendCommand(BleCommandCodec.requestStatus());
  }

  @override
  void dispose() {
    _statusSub.cancel();
    super.dispose();
  }
}

final ledControlControllerProvider =
    StateNotifierProvider<LedControlController, LedControlState>((ref) {
  final repo = ref.watch(bleRepositoryProvider);
  return LedControlController(repo);
});

/// Connection lifecycle state for the currently targeted device.
///
/// Kept as a single enum (rather than scattered booleans) so the UI layer
/// can exhaustively switch over it and never end up in an impossible
/// combined state like "connecting AND error".
enum ConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  reconnecting,
  error,
}

extension ConnectionStatusX on ConnectionStatus {
  bool get isBusy =>
      this == ConnectionStatus.connecting ||
      this == ConnectionStatus.scanning ||
      this == ConnectionStatus.reconnecting;

  String get label {
    switch (this) {
      case ConnectionStatus.disconnected:
        return 'Disconnected';
      case ConnectionStatus.scanning:
        return 'Scanning...';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.connected:
        return 'Connected';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.error:
        return 'Connection error';
    }
  }
}

import 'package:equatable/equatable.dart';

/// One BLE session, from successful connect to disconnect (whether the
/// user disconnected intentionally or the link ultimately failed after
/// automatic reconnection gave up).
class SessionLogEntry extends Equatable {
  final String deviceName;
  final DateTime startTime;
  final DateTime endTime;

  const SessionLogEntry({
    required this.deviceName,
    required this.startTime,
    required this.endTime,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() => {
        'deviceName': deviceName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      };

  factory SessionLogEntry.fromJson(Map<String, dynamic> json) {
    return SessionLogEntry(
      deviceName: json['deviceName'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
    );
  }

  @override
  List<Object?> get props => [deviceName, startTime, endTime];
}

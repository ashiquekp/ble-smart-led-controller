import 'package:equatable/equatable.dart';

/// A BLE device as seen by the app — either freshly discovered during a
/// scan, or loaded from local storage as "the last connected device".
class DeviceInfo extends Equatable {
  final String id; // platform BLE device identifier (MAC / UUID)
  final String name;
  final int rssi;

  const DeviceInfo({
    required this.id,
    required this.name,
    this.rssi = 0,
  });

  DeviceInfo copyWith({String? id, String? name, int? rssi}) {
    return DeviceInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      rssi: rssi ?? this.rssi,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'rssi': rssi,
      };

  factory DeviceInfo.fromJson(Map<String, dynamic> json) => DeviceInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        rssi: json['rssi'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [id, name, rssi];
}

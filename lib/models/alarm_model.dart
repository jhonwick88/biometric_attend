import 'package:flutter/material.dart';

class AlarmSettings {
  final bool checkInEnabled;
  final TimeOfDay checkInTime;
  final bool checkOutEnabled;
  final TimeOfDay checkOutTime;

  AlarmSettings({
    this.checkInEnabled = false,
    this.checkInTime = const TimeOfDay(hour: 8, minute: 0),
    this.checkOutEnabled = false,
    this.checkOutTime = const TimeOfDay(hour: 17, minute: 0),
  });

  AlarmSettings copyWith({
    bool? checkInEnabled,
    TimeOfDay? checkInTime,
    bool? checkOutEnabled,
    TimeOfDay? checkOutTime,
  }) {
    return AlarmSettings(
      checkInEnabled: checkInEnabled ?? this.checkInEnabled,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutEnabled: checkOutEnabled ?? this.checkOutEnabled,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }

  Map<String, String> toMap() {
    return {
      'checkInEnabled': checkInEnabled.toString(),
      'checkInHour': checkInTime.hour.toString(),
      'checkInMinute': checkInTime.minute.toString(),
      'checkOutEnabled': checkOutEnabled.toString(),
      'checkOutHour': checkOutTime.hour.toString(),
      'checkOutMinute': checkOutTime.minute.toString(),
    };
  }

  factory AlarmSettings.fromMap(Map<String, String> map) {
    return AlarmSettings(
      checkInEnabled: map['checkInEnabled'] == 'true',
      checkInTime: TimeOfDay(
        hour: int.tryParse(map['checkInHour'] ?? '8') ?? 8,
        minute: int.tryParse(map['checkInMinute'] ?? '0') ?? 0,
      ),
      checkOutEnabled: map['checkOutEnabled'] == 'true',
      checkOutTime: TimeOfDay(
        hour: int.tryParse(map['checkOutHour'] ?? '17') ?? 17,
        minute: int.tryParse(map['checkOutMinute'] ?? '0') ?? 0,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/alarm_model.dart';
import '../services/notification_service.dart';

class AlarmNotifier extends Notifier<AlarmSettings> {
  final _storage = const FlutterSecureStorage();

  @override
  AlarmSettings build() {
    // Memuat settings saat provider pertama kali diakses
    _loadSettings();
    return AlarmSettings();
  }

  Future<void> _loadSettings() async {
    final Map<String, String> all = await _storage.readAll();
    
    final modelMap = <String, String>{};
    for (var entry in all.entries) {
      if (entry.key.startsWith('alarm_')) {
        modelMap[entry.key.replaceFirst('alarm_', '')] = entry.value;
      }
    }

    if (modelMap.isNotEmpty) {
      state = AlarmSettings.fromMap(modelMap);
    }
  }

  Future<void> updateSettings(AlarmSettings newSettings) async {
    state = newSettings;
    final map = newSettings.toMap();
    for (var entry in map.entries) {
      await _storage.write(key: 'alarm_${entry.key}', value: entry.value);
    }
    await _rescheduleNotifications();
  }

  Future<void> _rescheduleNotifications() async {
    // Check-in Alarm (ID 100)
    await NotificationService.cancelNotification(100);
    if (state.checkInEnabled) {
      await NotificationService.scheduleDailyNotification(
        id: 100,
        title: 'Waktunya Check-In!',
        body: 'Jangan lupa melakukan absensi masuk pagi ini.',
        time: state.checkInTime,
      );
    }

    // Check-out Alarm (ID 200)
    await NotificationService.cancelNotification(200);
    if (state.checkOutEnabled) {
      await NotificationService.scheduleDailyNotification(
        id: 200,
        title: 'Waktunya Check-Out!',
        body: 'Pekerjaan selesai, jangan lupa absen pulang!',
        time: state.checkOutTime,
      );
    }
  }
}

final alarmProvider = NotifierProvider<AlarmNotifier, AlarmSettings>(AlarmNotifier.new);

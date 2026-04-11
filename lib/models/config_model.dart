import '../core/constants.dart';

class AppConfigModel {
  final bool showRegister;
  final String runningMessage;
  final double officeLat;
  final double officeLng;
  final double attendanceRadius;
  final int breakTimeMinutes;

  AppConfigModel({
    required this.showRegister,
    required this.runningMessage,
    required this.officeLat,
    required this.officeLng,
    required this.attendanceRadius,
    required this.breakTimeMinutes,
  });

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      showRegister: map['showRegister'] ?? true,
      runningMessage: map['runningMessage'] ?? '',
      officeLat: (map['officeLat'] as num?)?.toDouble() ?? AppConstants.officeLat,
      officeLng: (map['officeLng'] as num?)?.toDouble() ?? AppConstants.officeLng,
      attendanceRadius: (map['attendanceRadius'] as num?)?.toDouble() ?? AppConstants.attendanceRadius,
      breakTimeMinutes: (map['breakTimeMinutes'] as num?)?.toInt() ?? 30,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showRegister': showRegister,
      'runningMessage': runningMessage,
      'officeLat': officeLat,
      'officeLng': officeLng,
      'attendanceRadius': attendanceRadius,
      'breakTimeMinutes': breakTimeMinutes,
    };
  }

  AppConfigModel copyWith({
    bool? showRegister,
    String? runningMessage,
    double? officeLat,
    double? officeLng,
    double? attendanceRadius,
    int? breakTimeMinutes,
  }) {
    return AppConfigModel(
      showRegister: showRegister ?? this.showRegister,
      runningMessage: runningMessage ?? this.runningMessage,
      officeLat: officeLat ?? this.officeLat,
      officeLng: officeLng ?? this.officeLng,
      attendanceRadius: attendanceRadius ?? this.attendanceRadius,
      breakTimeMinutes: breakTimeMinutes ?? this.breakTimeMinutes,
    );
  }
}

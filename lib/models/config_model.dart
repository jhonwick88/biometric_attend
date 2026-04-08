class AppConfigModel {
  final bool showRegister;
  final String runningMessage;

  AppConfigModel({
    required this.showRegister,
    required this.runningMessage,
  });

  factory AppConfigModel.fromMap(Map<String, dynamic> map) {
    return AppConfigModel(
      showRegister: map['showRegister'] ?? true,
      runningMessage: map['runningMessage'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showRegister': showRegister,
      'runningMessage': runningMessage,
    };
  }

  AppConfigModel copyWith({
    bool? showRegister,
    String? runningMessage,
  }) {
    return AppConfigModel(
      showRegister: showRegister ?? this.showRegister,
      runningMessage: runningMessage ?? this.runningMessage,
    );
  }
}

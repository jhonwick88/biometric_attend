import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String username; // Added username field
  final bool biometricEnabled;
  final DateTime createdAt;
  final String role; // 'user', 'admin', 'dev'

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    this.biometricEnabled = false,
    required this.createdAt,
    this.role = 'user', // Default Role
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: map['uid'] ?? documentId,
      email: map['email'] ?? '',
      username: map['username'] ?? (map['email'] as String? ?? '').split('@').first, // Fallback if missing
      biometricEnabled: map['biometricEnabled'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: map['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'biometricEnabled': biometricEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
      'role': role,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    bool? biometricEnabled,
    DateTime? createdAt,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}

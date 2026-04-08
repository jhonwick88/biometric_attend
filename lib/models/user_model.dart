import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final bool biometricEnabled;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.biometricEnabled = false,
    required this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: map['uid'] ?? documentId,
      email: map['email'] ?? '',
      biometricEnabled: map['biometricEnabled'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'biometricEnabled': biometricEnabled,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

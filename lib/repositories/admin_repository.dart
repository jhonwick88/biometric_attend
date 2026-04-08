import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserModel>> watchAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('email')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> deleteUser(String uid) async {
    await _firestore.collection('users').doc(uid).delete();
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> register(String email, String password) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: cred.user!.uid,
        email: email,
        username: email.split('@').first,
        biometricEnabled: true, // Defaulting true for simplicity
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(newUser.uid)
          .set(newUser.toMap());

      return newUser;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Registrasi gagal');
    }
  }

  Future<UserModel> login(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot doc =
          await _firestore.collection('users').doc(cred.user!.uid).get();

      if (!doc.exists) {
        throw Exception('Data user di database tidak ditemukan.');
      }

      return UserModel.fromMap(
          doc.data() as Map<String, dynamic>, cred.user!.uid);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Login gagal');
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
    }
    return null;
  }
}

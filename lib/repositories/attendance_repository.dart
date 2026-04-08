import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';

class AttendanceRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getTodayString() {
    return DateTime.now().toString().substring(0, 10);
  }

  Future<bool> alreadyCheckIn(String uid) async {
    final today = _getTodayString();
    final result = await _firestore
        .collection('attendance')
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: today)
        .get();

    return result.docs.isNotEmpty;
  }

  Future<bool> alreadyCheckOut(String uid) async {
    final today = _getTodayString();
    final result = await _firestore
        .collection('attendance')
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: today)
        .get();

    if (result.docs.isEmpty) return false;
    
    final data = result.docs.first.data();
    return data['checkOut'] != null;
  }

  Future<void> checkIn(String uid, String email, Position position) async {
    final today = _getTodayString();
    
    AttendanceModel attendance = AttendanceModel(
      uid: uid,
      userEmail: email,
      date: today,
      checkIn: DateTime.now(),
      location: AttendanceLocation(lat: position.latitude, lng: position.longitude)
    );

    await _firestore.collection('attendance').add(attendance.toMap());
  }

  Future<void> checkOut(String uid) async {
    final today = _getTodayString();
    final result = await _firestore
        .collection('attendance')
        .where('uid', isEqualTo: uid)
        .where('date', isEqualTo: today)
        .get();

    if (result.docs.isNotEmpty) {
      await _firestore
          .collection('attendance')
          .doc(result.docs.first.id)
          .update({
        'checkOut': FieldValue.serverTimestamp(),
      });
    } else {
      throw "Data check-in tidak ditemukan untuk checkout";
    }
  }

  Stream<List<AttendanceModel>> getAttendanceHistory(String uid) {
    return _firestore
        .collection('attendance')
        .where('uid', isEqualTo: uid)
        .orderBy('checkIn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Admin: Get all attendance history
  Stream<List<AttendanceModel>> getAllAttendanceHistory() {
    return _firestore
        .collection('attendance')
        .orderBy('checkIn', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}

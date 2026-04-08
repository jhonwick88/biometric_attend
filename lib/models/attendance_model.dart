import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceLocation {
  final double lat;
  final double lng;

  AttendanceLocation({required this.lat, required this.lng});

  factory AttendanceLocation.fromMap(Map<String, dynamic> map) {
    return AttendanceLocation(
      lat: map['lat'] ?? 0.0,
      lng: map['lng'] ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class AttendanceModel {
  final String? id;
  final String uid;
  final String date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final AttendanceLocation location;

  AttendanceModel({
    this.id,
    required this.uid,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.location,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      id: documentId,
      uid: map['uid'] ?? '',
      date: map['date'] ?? '',
      checkIn: (map['checkIn'] as Timestamp?)?.toDate(),
      checkOut: (map['checkOut'] as Timestamp?)?.toDate(),
      location: AttendanceLocation.fromMap(map['location'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'date': date,
      'checkIn': checkIn != null ? Timestamp.fromDate(checkIn!) : FieldValue.serverTimestamp(),
      'checkOut': checkOut != null ? Timestamp.fromDate(checkOut!) : null,
      'location': location.toMap(),
    };
  }
}

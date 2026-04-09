import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS tidak aktif. Harap aktifkan GPS Anda.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen, harap buka pengaturan.');
    }

    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  /// Refactored to accept dynamic office location and radius
  Future<void> validateLocation({
    required double officeLat,
    required double officeLng,
    required double radius,
  }) async {
    final position = await getCurrentPosition();
    if (position == null) throw Exception("Tidak bisa mendapatkan lokasi");

    double distance = Geolocator.distanceBetween(
      officeLat,
      officeLng,
      position.latitude,
      position.longitude,
    );

    if (distance > radius) {
      throw Exception('Di luar area absensi (Jarak: ${distance.toStringAsFixed(1)}m)');
    }
  }
}

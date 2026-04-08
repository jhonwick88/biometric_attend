import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import '../repositories/attendance_repository.dart';
import '../services/biometric_service.dart';
import '../services/location_service.dart';
import 'auth_viewmodel.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => AttendanceRepository());
final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

final attendanceHistoryProvider = StreamProvider.autoDispose<List<AttendanceModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(attendanceRepositoryProvider).getAttendanceHistory(user.uid);
});

class AttendanceController extends AsyncNotifier<void> {

  @override
  FutureOr<void> build() {}

  Future<void> checkIn() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw "User belum login";

      final repo = ref.read(attendanceRepositoryProvider);
      
      // 1. Cek limit 1 hari
      bool alreadyCheckIn = await repo.alreadyCheckIn(user.uid);
      if (alreadyCheckIn) throw "Anda sudah absen masuk hari ini!";

      // 2. Validate Biometric
      final bioService = ref.read(biometricServiceProvider);
      bool authResult = await bioService.authenticate();
      if (!authResult) throw "Validasi biometrik gagal / dibatalkan";

      // 3. Validate Location
      final locService = ref.read(locationServiceProvider);
      await locService.validateLocation();
      final position = await locService.getCurrentPosition();

      // 4. Save to DB (Including Email)
      await repo.checkIn(user.uid, user.email ?? '', position!);
    });
  }

  Future<void> checkOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(authStateProvider).value;
      if (user == null) throw "User belum login";

      final repo = ref.read(attendanceRepositoryProvider);
      
      // 1. Pastikan sudah check-in
      bool alreadyCheckIn = await repo.alreadyCheckIn(user.uid);
      if (!alreadyCheckIn) throw "Anda belum absen masuk hari ini!";

      // 2. Cek limit check out
      bool alreadyCheckOut = await repo.alreadyCheckOut(user.uid);
      if (alreadyCheckOut) throw "Anda sudah absen pulang hari ini!";

      // 3. Validate Biometric
      final bioService = ref.read(biometricServiceProvider);
      bool authResult = await bioService.authenticate();
      if (!authResult) throw "Validasi biometrik gagal / dibatalkan";

      // 4. Validate Location
      final locService = ref.read(locationServiceProvider);
      await locService.validateLocation();

      // 5. Update DB
      await repo.checkOut(user.uid);
    });
  }
}

final attendanceControllerProvider = AsyncNotifierProvider<AttendanceController, void>(AttendanceController.new);

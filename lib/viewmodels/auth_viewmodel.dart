import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';
import '../services/biometric_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<fb.User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

class AuthController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).login(email, password);
      await ref.read(biometricServiceProvider).saveCredentials(email, password);
    });
  }

  Future<void> loginWithBiometrics() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final biometricService = ref.read(biometricServiceProvider);
      
      final isAvailable = await biometricService.isBiometricAvailable();
      if (!isAvailable) {
        throw Exception('Biometrik tidak tersedia di perangkat ini.');
      }

      final credentials = await biometricService.getCredentials();
      if (credentials == null) {
        throw Exception('Belum ada data login. Silakan login dengan email terlebih dahulu.');
      }

      final isAuthenticated = await biometricService.authenticate();
      if (isAuthenticated) {
         await ref.read(authRepositoryProvider).login(credentials['email']!, credentials['password']!);
      } else {
        throw Exception('Autentikasi biometrik dibatalkan atau gagal.');
      }
    });
  }

  Future<void> register(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).register(email, password);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    // Kita tidak menghapus credential di sini agar pengguna
    // tetap bisa menggunakan fitur login dengan sidik jari setelah logout.
    // await ref.read(biometricServiceProvider).clearCredentials();
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.read(authRepositoryProvider).getUserData(user.uid);
});

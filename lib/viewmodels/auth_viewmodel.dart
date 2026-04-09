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
  // Simpan password sementara untuk keperluan opt-in biometrik setelah login berhasil
  String? _lastPassword;
  String? get lastPassword => _lastPassword;

  @override
  FutureOr<void> build() {}

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(email, password);
      // Simpan sementara untuk keperluan opt-in/sync
      _lastPassword = password;

      // Sinkronisasi otomatis jika biometrik sudah aktif di akun ini
      if (user.biometricEnabled) {
        await ref.read(biometricServiceProvider).saveCredentials(email, password);
      }
    });
  }

  Future<void> toggleBiometricPreference(bool enabled) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final repo = ref.read(authRepositoryProvider);
    final bioService = ref.read(biometricServiceProvider);

    // Update Firestore
    final userData = await repo.getUserData(user.uid);
    if (userData != null) {
      final updatedUser = UserModel(
        uid: userData.uid,
        email: userData.email,
        username: userData.username,
        biometricEnabled: enabled,
        createdAt: userData.createdAt,
        role: userData.role,
      );
      await repo.updateUser(updatedUser);
      // Invalidate profile to refresh UI
      ref.invalidate(userProfileProvider);
    }

    if (enabled && _lastPassword != null) {
      await bioService.saveCredentials(user.email!, _lastPassword!);
    } else if (!enabled) {
      await bioService.clearCredentials();
    }
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
        throw Exception('Fitur Biometrik belum diaktifkan. Silakan login manual terlebih dahulu.');
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

  Future<void> forgotPassword(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
    });
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    _lastPassword = null;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, void>(AuthController.new);

final userProfileProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;
  return ref.read(authRepositoryProvider).getUserData(user.uid);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/attendance_model.dart';
import '../repositories/admin_repository.dart';
import 'attendance_viewmodel.dart'; // Import to get attendanceRepositoryProvider
import 'auth_viewmodel.dart'; // Import to check auth state

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository());

// Watch all users for CRUD
final allUsersProvider = StreamProvider<List<UserModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(adminRepositoryProvider).watchAllUsers();
});

// Watch all attendance for history
final allAttendanceProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }
  return ref.watch(attendanceRepositoryProvider).getAllAttendanceHistory();
});

class AdminController extends Notifier<void> {
  @override
  void build() {}

  Future<void> updateUser(UserModel user) async {
    await ref.read(adminRepositoryProvider).updateUser(user);
  }

  Future<void> deleteUser(String uid) async {
    await ref.read(adminRepositoryProvider).deleteUser(uid);
  }
}

final adminControllerProvider = NotifierProvider<AdminController, void>(AdminController.new);

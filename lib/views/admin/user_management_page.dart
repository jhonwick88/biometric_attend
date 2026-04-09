import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../viewmodels/admin_viewmodel.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola User'),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (users) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _buildUserCard(context, ref, user);
            },
          );
        },
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, WidgetRef ref, UserModel user) {
    final bool isAdmin = user.role == 'admin' || user.role == 'dev';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: isAdmin 
            ? [const Color(0xFF2B32B2), const Color(0xFF1488CC)]
            : [const Color(0xFFFF6F91), const Color(0xFFFF9671)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  user.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (user.biometricEnabled)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.fingerprint, color: Colors.white70, size: 20),
                ),
            ],
          ),
          subtitle: Text(
            'Role: ${user.role.toUpperCase()}',
            style: const TextStyle(color: Colors.white70),
          ),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'edit') {
                _showEditRoleDialog(context, ref, user);
              } else if (value == 'delete') {
                _showDeleteDialog(context, ref, user);
              } else if (value == 'reset_bio') {
                _showResetBiometricDialog(context, ref, user);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Ubah Role')),
              if (user.biometricEnabled)
                const PopupMenuItem(value: 'reset_bio', child: Text('Reset Biometrik')),
              const PopupMenuItem(value: 'delete', child: Text('Hapus User', style: TextStyle(color: Colors.red))),
            ],
          ),
        ),
      ),
    );
  }

  void _showResetBiometricDialog(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Biometrik'),
        content: Text('Apakah Anda yakin ingin menonaktifkan fitur Quick Login untuk ${user.username}? User harus login manual kembali untuk mengaktifkannya.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final updatedUser = UserModel(
                uid: user.uid,
                email: user.email,
                username: user.username,
                biometricEnabled: false,
                createdAt: user.createdAt,
                role: user.role,
              );
              ref.read(adminControllerProvider.notifier).updateUser(updatedUser);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Biometrik ${user.username} berhasil di-reset!')),
              );
            },
            child: const Text('Reset Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (context) {
        String selectedRole = user.role;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Ubah Role User'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: ['user', 'admin', 'dev'].map((role) {
                  return RadioListTile<String>(
                    title: Text(role.toUpperCase()),
                    value: role,
                    groupValue: selectedRole,
                    onChanged: (value) {
                      setState(() => selectedRole = value!);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                ElevatedButton(
                  onPressed: () {
                    final updatedUser = UserModel(
                      uid: user.uid,
                      email: user.email,
                      username: user.username,
                      biometricEnabled: user.biometricEnabled,
                      createdAt: user.createdAt,
                      role: selectedRole,
                    );
                    ref.read(adminControllerProvider.notifier).updateUser(updatedUser);
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus User'),
        content: Text('Apakah Anda yakin ingin menghapus ${user.email}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(adminControllerProvider.notifier).deleteUser(user.uid);
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

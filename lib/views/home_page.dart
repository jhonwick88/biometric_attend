import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../viewmodels/attendance_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final historyAsyncValue = ref.watch(attendanceHistoryProvider);

    ref.listen<AsyncValue>(
      attendanceControllerProvider,
      (_, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString()),
              backgroundColor: Colors.redAccent,
            ),
          );
        } else if (!state.isLoading && state.hasValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Operasi berhasil!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Attendance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Keluar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                ref.read(authControllerProvider.notifier).logout();
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: Column(
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        icon: const Icon(Icons.login, size: 20),
                        label: const Text('Masuk', style: TextStyle(fontSize: 14)),
                        onPressed: attendanceState.isLoading
                            ? null
                            : () {
                                ref.read(attendanceControllerProvider.notifier).checkIn();
                              },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade800,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        icon: const Icon(Icons.logout, size: 20),
                        label: const Text('Pulang', style: TextStyle(fontSize: 14)),
                        onPressed: attendanceState.isLoading
                            ? null
                            : () {
                                ref.read(attendanceControllerProvider.notifier).checkOut();
                              },
                      ),
                    ),
                  ],
                ),
                if (attendanceState.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: CircularProgressIndicator(),
                  )
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: historyAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (history) {
                if (history.isEmpty) {
                  return const Center(child: Text('Belum ada riwayat absensi.'));
                }
                return ListView.builder(
                  itemCount: history.length,
                  itemBuilder: (context, index) {
                    final att = history[index];
                    final DateFormat formatTime = DateFormat('HH:mm');

                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.history)),
                      title: Text(att.date),
                      subtitle: Text(
                        'Masuk: ${att.checkIn != null ? formatTime.format(att.checkIn!) : '-'}  |  '
                        'Pulang: ${att.checkOut != null ? formatTime.format(att.checkOut!) : '-'}',
                      ),
                      trailing: att.checkOut != null
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.pending, color: Colors.orange),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

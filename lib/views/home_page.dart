import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:marquee/marquee.dart';
import '../models/user_model.dart';
import '../viewmodels/attendance_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/config_viewmodel.dart';
import 'admin/user_management_page.dart';
import 'admin/all_attendance_page.dart';
import 'admin/settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final historyAsyncValue = ref.watch(attendanceHistoryProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final configAsync = ref.watch(appConfigProvider);

    final bool isAdminOrDev = userProfileAsync.asData?.value?.role == 'admin' || userProfileAsync.asData?.value?.role == 'dev';

    ref.listen<AsyncValue>(
      attendanceControllerProvider,
      (_, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString()),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (!state.isLoading && state.hasValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Operasi berhasil!'),
              backgroundColor: const Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: isAdminOrDev ? _buildAdminDrawer(context, userProfileAsync.asData!.value!) : null,
      appBar: AppBar(
        title: const Text('Dashboard Kehadiran'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () async {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Konfirmasi Logout'),
                  content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Keluar', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFE4EC), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---------------- MARQUEE MESSAGE ----------------
            configAsync.when(
              data: (config) => config.runningMessage.isNotEmpty
                  ? Container(
                      height: 35,
                      color: const Color(0xFFFF6F91).withOpacity(0.1),
                      child: Marquee(
                        text: config.runningMessage,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6F91), fontSize: 13),
                        scrollAxis: Axis.horizontal,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        blankSpace: 200.0,
                        velocity: 50.0,
                        pauseAfterRound: const Duration(seconds: 1),
                        startPadding: 10.0,
                        accelerationDuration: const Duration(seconds: 1),
                        accelerationCurve: Curves.linear,
                        decelerationDuration: const Duration(milliseconds: 500),
                        decelerationCurve: Curves.easeOut,
                      ),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            // ---------------- HEADER / CURRENT DATE ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Hari Ini",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // ---------------- ACTIONS BUTTON ----------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      title: "Masuk",
                      icon: Icons.login_rounded,
                      color: const Color(0xFF4CAF50), // Soft Green
                      isLoading: attendanceState.isLoading,
                      onTap: () => ref.read(attendanceControllerProvider.notifier).checkIn(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      title: "Pulang",
                      icon: Icons.logout_rounded,
                      color: const Color(0xFFFF6F91), // Pink Theme
                      isLoading: attendanceState.isLoading,
                      onTap: () => ref.read(attendanceControllerProvider.notifier).checkOut(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ---------------- HISTORY TITLE ----------------
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                "Riwayat Absensi",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ---------------- HISTORY LIST ----------------
            Expanded(
              child: historyAsyncValue.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'Error: $err',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                data: (history) {
                  if (history.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada riwayat absensi.',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final att = history[index];
                      final DateFormat formatTime = DateFormat('HH:mm');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: (att.checkOut != null
                                      ? const Color(0xFF4CAF50)
                                      : const Color(0xFFD4AF37))
                                  .withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              att.checkOut != null ? Icons.fact_check_rounded : Icons.pending_actions_rounded,
                              color: att.checkOut != null ? const Color(0xFF4CAF50) : const Color(0xFFD4AF37),
                            ),
                          ),
                          title: Text(
                            att.date,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              'Masuk: ${att.checkIn != null ? formatTime.format(att.checkIn!) : '-'}  •  '
                              'Pulang: ${att.checkOut != null ? formatTime.format(att.checkOut!) : '-'}',
                              style: const TextStyle(fontSize: 13, color: Colors.black54),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Komponen khusus untuk tombol absensi besar 
  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required bool isLoading,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(24),
        splashColor: color.withOpacity(0.2),
        highlightColor: color.withOpacity(0.1),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
            border: Border.all(color: color.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            children: [
              isLoading
                  ? SizedBox(
                      height: 36,
                      width: 36,
                      child: CircularProgressIndicator(color: color, strokeWidth: 3.5),
                    )
                  : Icon(icon, size: 38, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminDrawer(BuildContext context, UserModel user) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2B32B2), Color(0xFF1488CC)], // Modern Dev/Admin Deep Blue Gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              user.role.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16),
            ),
            accountEmail: Text(user.email, style: const TextStyle(color: Colors.white70)),
            currentAccountPicture: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings, size: 40, color: Color(0xFF2B32B2)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined, color: Colors.black87),
            title: const Text('Kelola User', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.history_edu_rounded, color: Colors.black87),
            title: const Text('Seluruh Riwayat Absen', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAttendancePage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Colors.black87),
            title: const Text('Setting Aplikasi', style: TextStyle(fontWeight: FontWeight.w500)),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Version 1.0.0 (Developer Tools)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

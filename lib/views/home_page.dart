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

import 'widgets/biometric_bottom_sheet.dart';
import '../services/biometric_service.dart';
import 'self_attendance_history_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _hasPromptedBiometric = false;

  @override
  Widget build(BuildContext context) {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final historyAsyncValue = ref.watch(attendanceHistoryProvider);
    final userProfileAsync = ref.watch(userProfileProvider);
    final configAsync = ref.watch(appConfigProvider);

    // --- BRAND COLORS ---
    const primaryColor = Color(0xFFFF6F91); // Soft Pink
    const accentColor = Color(0xFFFF9671); // Soft Orange
    const successColor = Color(0xFF4CAF50); // Balanced Green
    const warningColor = Color(0xFFFF9671); // Warning Pink-Orange
    const backgroundColor = Color(0xFFFFEEF2);

    final bool isAdminOrDev = userProfileAsync.asData?.value?.role == 'admin' || userProfileAsync.asData?.value?.role == 'dev';

    // --- CALCULATE STATS ---
    DateTime? todayCheckIn;
    DateTime? todayCheckOut;
    String totalWorkTime = "0h 0m";
    final DateFormat timeFormat = DateFormat('HH:mm');
    List<double> weeklyHours = [0, 0, 0, 0, 0, 0, 0];

    if (historyAsyncValue.hasValue) {
      final history = historyAsyncValue.value!;
      final todayStr = DateTime.now().toString().substring(0, 10);
      
      // Today Stats
      try {
        final todayData = history.firstWhere((a) => a.date == todayStr);
        todayCheckIn = todayData.checkIn;
        todayCheckOut = todayData.checkOut;

        if (todayCheckIn != null && todayCheckOut != null) {
          final breakTimeMinutes = configAsync.value?.breakTimeMinutes ?? 30;
          final diff = todayCheckOut!.difference(todayCheckIn!);
          final totalMinutes = diff.inMinutes - breakTimeMinutes;
          
          if (totalMinutes > 0) {
            totalWorkTime = "${totalMinutes ~/ 60}h ${totalMinutes % 60}m";
          } else {
            totalWorkTime = "0h 0m";
          }
        }
      } catch (_) {}

      // Weekly Stats (last 7 days)
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.subtract(Duration(days: i));
        final dStr = date.toString().substring(0, 10);
        try {
          final att = history.firstWhere((a) => a.date == dStr);
          if (att.checkIn != null && att.checkOut != null) {
            final h = att.checkOut!.difference(att.checkIn!).inMinutes / 60.0;
            weeklyHours[6 - i] = h > 8 ? 8 : h; // Cap at 8 for visual
          }
        } catch (_) {}
      }
    }

    ref.listen<AsyncValue<UserModel?>>(
      userProfileProvider,
      (previous, next) async {
        if (next.hasValue && next.value != null && !_hasPromptedBiometric) {
          final user = next.value!;
          final bioService = ref.read(biometricServiceProvider);
          final isAvailable = await bioService.isBiometricAvailable();

          if (isAvailable && !user.biometricEnabled) {
            _hasPromptedBiometric = true;
            if (!mounted) return;
            
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (context) => BiometricBottomSheet(
                onEnable: () async {
                  Navigator.pop(context);
                  await ref.read(authControllerProvider.notifier).toggleBiometricPreference(true);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Quick Login Berhasil Diaktifkan!')),
                    );
                  }
                },
                onCancel: () {
                  Navigator.pop(context);
                },
              ),
            );
          }
        }
      },
    );

    ref.listen<AsyncValue>(
      attendanceControllerProvider,
      (_, state) {
        if (state.hasError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error.toString()),
              backgroundColor: const Color(0xFFD32F2F),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else if (!state.isLoading && state.hasValue) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Operasi berhasil!'),
              backgroundColor: successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: (userProfileAsync.value != null) 
          ? _buildMainDrawer(context, userProfileAsync.value!) 
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: attendanceState.isLoading 
        ? null // Hide or show loading while processing
        : AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: todayCheckIn == null
                ? _buildFloatingActionButton(
                    key: const ValueKey('check_in'),
                    title: "Check In",
                    icon: Icons.fingerprint_rounded,
                    color: successColor,
                    onTap: () => ref.read(attendanceControllerProvider.notifier).checkIn(),
                  )
                : (todayCheckOut == null
                    ? _buildFloatingActionButton(
                        key: const ValueKey('check_out'),
                        title: "Check Out",
                        icon: Icons.fingerprint_rounded,
                        color: warningColor,
                        onTap: () => ref.read(attendanceControllerProvider.notifier).checkOut(),
                      )
                    : const SizedBox.shrink()), // Hide if both done
          ),
      body: Stack(
        children: [
          // Background Gradient Decorations
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 400,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withOpacity(0.05),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ---------------- CUSTOM SLIVER APP BAR ----------------
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: backgroundColor,
                elevation: 0,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.grid_view_rounded, color: primaryColor, size: 26),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.black54, size: 22),
                      onPressed: () {
                        _handleLogout(context, ref);
                        //Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                      },
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
                  titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  background: Container(
                    padding: const EdgeInsets.only(top: 85, left: 24, right: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting().toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: primaryColor.withOpacity(0.8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          userProfileAsync.value?.username ?? "Team Member",
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A1A),
                            letterSpacing: -1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
// ... (omitting middle parts for succinctness in thought, but tool will use full context if I provide it carefully)
// Wait, I should provide the exact lines to replace.

              // ---------------- MARQUEE MESSAGE ----------------
              SliverToBoxAdapter(
                child: configAsync.when(
                  data: (config) => config.runningMessage.isNotEmpty
                      ? Container(
                          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          height: 40,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(color: primaryColor.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Marquee(
                              text: config.runningMessage,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                              scrollAxis: Axis.horizontal,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              blankSpace: 150.0,
                              velocity: 45.0,
                              pauseAfterRound: const Duration(seconds: 2),
                              startPadding: 10.0,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),

              // ---------------- STATUS & DATE CARD ----------------
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.08),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('EEEE, d MMMM').format(DateTime.now()),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black45,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Status Kehadiran",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: (todayCheckOut != null ? warningColor : (todayCheckIn != null ? successColor : Colors.grey)).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: (todayCheckOut != null ? warningColor : (todayCheckIn != null ? successColor : Colors.grey)).withOpacity(0.2)),
                              ),
                              child: Text(
                                todayCheckOut != null ? "SELESAI" : (todayCheckIn != null ? "SEDANG BEKERJA" : "BELUM ABSEN"),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: (todayCheckOut != null ? warningColor : (todayCheckIn != null ? successColor : Colors.grey)),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildSummaryItem("CHECK IN", todayCheckIn != null ? timeFormat.format(todayCheckIn) : "--:--", Icons.login_rounded, successColor),
                            _buildSummaryItem("CHECK OUT", todayCheckOut != null ? timeFormat.format(todayCheckOut) : "--:--", Icons.logout_rounded, warningColor),
                            _buildSummaryItem("DURATION", totalWorkTime, Icons.watch_later_outlined, primaryColor),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------- WEEKLY SUMMARY CHART ----------------
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(24),
                      image: DecorationImage(
                        image: const NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
                        opacity: 0.05,
                        repeat: ImageRepeat.repeat,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Weekly Performance",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Icon(Icons.insights_rounded, color: Colors.white70, size: 20),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 100,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (int i = 0; i < 7; i++)
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    AnimatedContainer(
                                      duration: const Duration(milliseconds: 800),
                                      curve: Curves.easeOutBack,
                                      width: 12,
                                      height: (weeklyHours[i] / 8) * 70 + 5,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [accentColor, accentColor.withOpacity(0.4)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ['S','M', 'T', 'W', 'T', 'F', 'S'][i],
                                      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Visualisasi performa kerja Anda selama 7 hari terakhir.",
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ---------------- RECENT HISTORY HEADER ----------------
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                sliver: SliverToBoxAdapter(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SelfAttendanceHistoryPage()),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Recent History",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: primaryColor.withOpacity(0.8),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: primaryColor.withOpacity(0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ---------------- HISTORY LIST ----------------
              historyAsyncValue.when(
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (err, stack) => SliverFillRemaining(
                  child: Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
                ),
                data: (history) {
                  if (history.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No records found.',
                          style: TextStyle(color: Colors.black38, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final att = history[index];
                          final bool isCheckOut = att.checkOut != null;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 45,
                                  height: 45,
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.calendar_today_rounded,
                                    color: primaryColor.withOpacity(0.5),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        att.date,
                                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF333333)),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${att.checkIn != null ? timeFormat.format(att.checkIn!) : '--'} - ${att.checkOut != null ? timeFormat.format(att.checkOut!) : '--'}',
                                        style: const TextStyle(fontSize: 13, color: Colors.black45, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  isCheckOut ? Icons.check_circle_rounded : Icons.pending_rounded,
                                  color: isCheckOut ? successColor : warningColor,
                                  size: 24,
                                )
                              ],
                            ),
                          );
                        },
                        childCount: history.take(5).length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Helpers ---

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Konfirmasi Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Color(0xFFFF4874), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ref.read(authControllerProvider.notifier).logout();
    }
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildFloatingActionButton({
    required Key key,
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      key: key,
      width: 105,
      height: 105,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.9),
            color,
          ],
          center: Alignment.center,
          radius: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 2,
            offset: const Offset(0, 15),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.transparent, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 42),
                const SizedBox(height: 6),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainDrawer(BuildContext context, UserModel user) {
    const primaryColor = Color(0xFFFF6F91); // Soft Pink
    const accentColor = Color(0xFFFF9671); // Soft Orange

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(28, 80, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor.withOpacity(0.08), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      user.username.isNotEmpty ? user.username.substring(0, 1).toUpperCase() : "?",
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  user.username,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                if (user.role == 'admin' || user.role == 'dev') ...[
                  _buildSectionHeader("ADMINISTRATION"),
                  _buildDrawerItem(
                    icon: Icons.manage_accounts_rounded,
                    title: "User Management",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManagementPage()));
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics_rounded,
                    title: "Attendance Logs",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AllAttendancePage()));
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                _buildSectionHeader("SYSTEM"),
                _buildDrawerItem(
                  icon: Icons.settings_rounded,
                  title: "Settings",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.shield_moon_rounded,
                  title: "Privacy & Security",
                  onTap: () {},
                ),
                _buildDrawerItem(
                  icon: Icons.help_center_rounded,
                  title: "Support Center",
                  onTap: () {},
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              children: [
                const Divider(color: Colors.black12, thickness: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.shield_rounded, size: 12, color: primaryColor),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Biometric Attend v2.0',
                      style: TextStyle(
                        color: Colors.black26,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: Colors.black26,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF6F91), size: 22),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF333333),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/config_model.dart';
import '../../viewmodels/config_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/biometric_service.dart';
import '../../models/alarm_model.dart';
import '../../viewmodels/alarm_viewmodel.dart';
import '../../services/notification_service.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _messageController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController();
  final _breakTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Request notification permissions gracefully when settings is opened
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService.initialize();
      
      final config = ref.read(appConfigProvider).asData?.value;
      if (config != null) {
        _messageController.text = config.runningMessage;
        _latController.text = config.officeLat.toString();
        _lngController.text = config.officeLng.toString();
        _radiusController.text = config.attendanceRadius.toString();
        _breakTimeController.text = config.breakTimeMinutes.toString();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    _breakTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);
    final alarmSettings = ref.watch(alarmProvider);

    // --- BRAND COLORS ---
    const primaryColor = Color(0xFFFF6F91);
    const accentColor = Color(0xFFFF9671);
    const backgroundColor = Color(0xFFFFEEF2);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: primaryColor)),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.redAccent))),
        data: (config) {
          final userAsync = ref.watch(userProfileProvider);
          final user = userAsync.asData?.value;
          final bool isAdminOrDev = user?.role == 'admin' || user?.role == 'dev';
          final bool isDev = user?.role == 'dev';

          return Stack(
            children: [
              // Background Decorations
              Positioned(
                top: -100,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withOpacity(0.4),
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
                    color: accentColor.withOpacity(0.3),
                  ),
                ),
              ),

              FutureBuilder<bool>(
                future: ref.read(biometricServiceProvider).isBiometricAvailable(),
                builder: (context, snapshot) {
                  final bool isBioAvailable = snapshot.data ?? false;

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      // ---------------- CUSTOM SLIVER APP BAR ----------------
                      SliverAppBar(
                        expandedHeight: 120,
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.transparent,
                        scrolledUnderElevation: 0,
                        elevation: 0,
                        leading: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        flexibleSpace: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              color: backgroundColor.withOpacity(0.5),
                              child: const FlexibleSpaceBar(
                                titlePadding: EdgeInsets.only(left: 54, right: 16, bottom: 16),
                                centerTitle: false,
                                title: Text(
                                  "Pengaturan",
                                  style: TextStyle(
                                    color: Color(0xFF1A1A1A),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    fontSize: 21,
                                  ),
                                ),
                                background: Align(
                                  alignment: Alignment.topLeft,
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 60, left: 54),
                                    child: Text(
                                      "BIO-ATTEND",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // 1. KEAMANAN & LOGIN
                            _buildSectionHeader("KEAMANAN & LOGIN"),
                            const SizedBox(height: 16),
                            
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Column(
                                children: [
                                  if (isBioAvailable)
                                    SwitchListTile(
                                      title: const Text('Login Biometrik', style: TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: const Text('Sidik jari atau pengenalan wajah.'),
                                      value: user?.biometricEnabled ?? false,
                                      activeColor: primaryColor,
                                      onChanged: (value) async {
                                        await ref.read(authControllerProvider.notifier).toggleBiometricPreference(value);
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(value ? 'Biometrik diaktifkan!' : 'Biometrik dinonaktifkan!')),
                                          );
                                        }
                                      },
                                    )
                                  else
                                    const ListTile(
                                      title: Text('Quick Login', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                      subtitle: Text('Hardware biometrik tidak dideteksi.', style: TextStyle(color: Colors.grey)),
                                      trailing: Icon(Icons.lock_outline, color: Colors.grey),
                                    ),
                                ],
                              ),
                            ),

                            // 1.1 ALARM PENGINGAT (BARU)
                            const SizedBox(height: 32),
                            _buildSectionHeader("ALARM PENGINGAT"),
                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Column(
                                children: [
                                  _buildAlarmRow(
                                    context,
                                    ref,
                                    title: 'Pengingat Check-In',
                                    isEnabled: alarmSettings.checkInEnabled,
                                    time: alarmSettings.checkInTime,
                                    onToggle: (val) => ref.read(alarmProvider.notifier).updateSettings(alarmSettings.copyWith(checkInEnabled: val)),
                                    onTimeTap: () => _pickTime(context, ref, alarmSettings, true),
                                  ),
                                  const Divider(indent: 16, endIndent: 16),
                                  _buildAlarmRow(
                                    context,
                                    ref,
                                    title: 'Pengingat Check-Out',
                                    isEnabled: alarmSettings.checkOutEnabled,
                                    time: alarmSettings.checkOutTime,
                                    onToggle: (val) => ref.read(alarmProvider.notifier).updateSettings(alarmSettings.copyWith(checkOutEnabled: val)),
                                    onTimeTap: () => _pickTime(context, ref, alarmSettings, false),
                                  ),
                                ],
                              ),
                            ),

                            // 2. ADMIN TOOLS (KHUSUS ADMIN/DEV)
                            if (isAdminOrDev) ...[
                              const SizedBox(height: 32),
                              _buildSectionHeader("ADMIN TOOLS", color: Colors.blueAccent),
                              const SizedBox(height: 16),
                              
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    SwitchListTile(
                                      title: const Text('Tombol Registrasi', style: TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: const Text('Kontrol registrasi user baru.'),
                                      value: config.showRegister,
                                      activeColor: Colors.blueAccent,
                                      onChanged: (value) {
                                        ref.read(configControllerProvider.notifier).updateConfig(
                                          config.copyWith(showRegister: value),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                              const Text('Pesan Pengumuman', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.blueAccent)),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _messageController,
                                decoration: InputDecoration(
                                  hintText: 'Tulis pesan marquee...',
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.all(20),
                                ),
                                maxLines: 2,
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  onPressed: () {
                                    ref.read(configControllerProvider.notifier).updateConfig(
                                      config.copyWith(runningMessage: _messageController.text),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Pengumuman diperbarui!')),
                                    );
                                  },
                                  child: const Text('Simpan Pengumuman', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],

                            // 3. DEVELOPER TOOLS (KHUSUS ROLE DEV SAJA)
                            if (isDev) ...[
                              const SizedBox(height: 32),
                              _buildSectionHeader("DEVELOPER SETTINGS", color: Colors.deepPurple),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Column(
                                  children: [
                                    _buildDevTextField(_latController, 'Office Latitude', Icons.location_on),
                                    const SizedBox(height: 12),
                                    _buildDevTextField(_lngController, 'Office Longitude', Icons.map),
                                    const SizedBox(height: 12),
                                    _buildDevTextField(_radiusController, 'Radius (Meter)', Icons.radar, suffix: 'm'),
                                    const SizedBox(height: 12),
                                    _buildDevTextField(_breakTimeController, 'Break (Minutes)', Icons.timer, suffix: 'min'),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  onPressed: () {
                                    final lat = double.tryParse(_latController.text) ?? config.officeLat;
                                    final lng = double.tryParse(_lngController.text) ?? config.officeLng;
                                    final radius = double.tryParse(_radiusController.text) ?? config.attendanceRadius;
                                    final breakTime = int.tryParse(_breakTimeController.text) ?? config.breakTimeMinutes;

                                    ref.read(configControllerProvider.notifier).updateConfig(
                                      config.copyWith(
                                        officeLat: lat,
                                        officeLng: lng,
                                        attendanceRadius: radius,
                                        breakTimeMinutes: breakTime,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Konfigurasi dev disimpan!')),
                                    );
                                  },
                                  child: const Text('Simpan Konfigurasi Dev', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ]),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = const Color(0xFFFF6F91)}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 14,
          letterSpacing: 1.2,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDevTextField(TextEditingController controller, String label, IconData icon, {String? suffix}) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.deepPurple.withOpacity(0.5)),
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildAlarmRow(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required bool isEnabled,
    required TimeOfDay time,
    required Function(bool) onToggle,
    required VoidCallback onTimeTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                InkWell(
                  onTap: onTimeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      time.format(context),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFFFF6F91)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onToggle,
            activeColor: const Color(0xFFFF6F91),
          ),
        ],
      ),
    );
  }

  void _pickTime(BuildContext context, WidgetRef ref, AlarmSettings settings, bool isCheckIn) async {
    final initialTime = isCheckIn ? settings.checkInTime : settings.checkOutTime;
    final time = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF6F91),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) {
      if (isCheckIn) {
        ref.read(alarmProvider.notifier).updateSettings(settings.copyWith(checkInTime: time));
      } else {
        ref.read(alarmProvider.notifier).updateSettings(settings.copyWith(checkOutTime: time));
      }
    }
  }
}

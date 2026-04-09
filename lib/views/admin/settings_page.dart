import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/config_model.dart';
import '../../viewmodels/config_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../services/biometric_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current config values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(appConfigProvider).asData?.value;
      if (config != null) {
        _messageController.text = config.runningMessage;
        _latController.text = config.officeLat.toString();
        _lngController.text = config.officeLng.toString();
        _radiusController.text = config.attendanceRadius.toString();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (config) {
          final userAsync = ref.watch(userProfileProvider);
          final user = userAsync.asData?.value;
          final bool isAdminOrDev = user?.role == 'admin' || user?.role == 'dev';
          final bool isDev = user?.role == 'dev';

          return FutureBuilder<bool>(
            future: ref.read(biometricServiceProvider).isBiometricAvailable(),
            builder: (context, snapshot) {
              final bool isBioAvailable = snapshot.data ?? false;

              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // 1. KEAMANAN & LOGIN (UNTUK SEMUA USER)
                  const Text('Keamanan & Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 16),
                  if (isBioAvailable)
                    SwitchListTile(
                      title: const Text('Quick Login dengan Biometrik'),
                      subtitle: const Text('Masuk aplikasi lebih cepat menggunakan sidik jari/wajah.'),
                      value: user?.biometricEnabled ?? false,
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
                      title: Text('Quick Login', style: TextStyle(color: Colors.grey)),
                      subtitle: Text('Hardware biometrik tidak dideteksi atau tidak didukung.', style: TextStyle(color: Colors.grey)),
                      trailing: Icon(Icons.lock_outline, color: Colors.grey),
                    ),
                  
                  // 2. ADMIN TOOLS (KHUSUS ADMIN/DEV)
                  if (isAdminOrDev) ...[
                    const Divider(height: 48),
                    const Text('Admin: Halaman Depan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Tampilkan Tombol Register'),
                      subtitle: const Text('Kontrol visibilitas registrasi untuk user baru.'),
                      value: config.showRegister,
                      onChanged: (value) {
                        ref.read(configControllerProvider.notifier).updateConfig(
                          config.copyWith(showRegister: value),
                        );
                      },
                    ),
                    const Divider(height: 48),
                    const Text('Admin: Pesan Pengumuman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Pesan berjalan di Home Page...',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        ref.read(configControllerProvider.notifier).updateConfig(
                          config.copyWith(runningMessage: _messageController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pengumuman diperbarui!')),
                        );
                      },
                      child: const Text('Simpan Pengumuman'),
                    ),
                  ],

                  // 3. DEVELOPER TOOLS (KHUSUS ROLE DEV SAJA)
                  if (isDev) ...[
                    const Divider(height: 48),
                    const Text('Developer: Konfigurasi Lokasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepPurple)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Office Latitude'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Office Longitude'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Attendance Radius (Meter)', suffixText: 'm'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                      onPressed: () {
                        final lat = double.tryParse(_latController.text) ?? config.officeLat;
                        final lng = double.tryParse(_lngController.text) ?? config.officeLng;
                        final radius = double.tryParse(_radiusController.text) ?? config.attendanceRadius;

                        ref.read(configControllerProvider.notifier).updateConfig(
                          config.copyWith(
                            officeLat: lat,
                            officeLng: lng,
                            attendanceRadius: radius,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Konfigurasi lokasi berhasil disimpan!')),
                        );
                      },
                      child: const Text('Simpan Konfigurasi'),
                    ),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

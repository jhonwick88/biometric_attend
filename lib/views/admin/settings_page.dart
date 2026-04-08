import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/config_model.dart';
import '../../viewmodels/config_viewmodel.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize controller with current config value
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final config = ref.read(appConfigProvider).asData?.value;
      if (config != null) {
        _messageController.text = config.runningMessage;
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Aplikasi'),
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (config) {
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text('Halaman Depan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Tampilkan Tombol Register'),
                subtitle: const Text('Aktifkan jika ingin membuka pendaftaran user baru.'),
                value: config.showRegister,
                onChanged: (value) {
                  ref.read(configControllerProvider.notifier).updateConfig(
                    config.copyWith(showRegister: value),
                  );
                },
              ),
              const Divider(height: 48),
              const Text('Konten Home Page', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              const Text('Pesan Berjalan (Marquee)'),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Masukkan pengumuman atau pesan singkat...',
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
                    const SnackBar(content: Text('Pesan berjalan diperbarui!')),
                  );
                },
                child: const Text('Simpan Pesan'),
              ),
            ],
          );
        },
      ),
    );
  }
}

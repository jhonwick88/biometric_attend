import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/config_model.dart';
import '../repositories/config_repository.dart';
import 'auth_viewmodel.dart';

final configRepositoryProvider = Provider<ConfigRepository>((ref) => ConfigRepository());

final appConfigProvider = StreamProvider<AppConfigModel>((ref) {
  return ref.watch(configRepositoryProvider).watchConfig();
});

class ConfigController extends Notifier<void> {
  @override
  void build() {}

  Future<void> updateConfig(AppConfigModel config) async {
    await ref.read(configRepositoryProvider).updateConfig(config);
  }
}

final configControllerProvider = NotifierProvider<ConfigController, void>(ConfigController.new);

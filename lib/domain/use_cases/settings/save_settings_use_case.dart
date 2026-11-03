import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/settings_repository.dart';
import 'package:gestor_tareas_personales/domain/states/settings_state.dart';

class SaveSettingsUseCase {
  final SettingsRepository settingsRepository;
  final SettingsState settingsState;

  SaveSettingsUseCase({
    required this.settingsRepository,
    required this.settingsState,
  });

  Future<AsyncState<void>> saveSettings(SettingsEntity settings) async {
    final response = await settingsRepository.saveSettings(settings);
    if (response.isSuccess) settingsState.setSettings(settings);
    return response;
  }
}

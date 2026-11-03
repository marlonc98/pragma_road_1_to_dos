import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/settings_repository.dart';
import 'package:gestor_tareas_personales/domain/states/settings_state.dart';

class GetSettingsUseCase {
  final SettingsRepository settingsRepository;
  final SettingsState settingsState;

  GetSettingsUseCase({
    required this.settingsRepository,
    required this.settingsState,
  });

  /// Si falla, el estado se queda con los valores por defecto.
  Future<AsyncState<SettingsEntity>> getSettings() async {
    final response = await settingsRepository.getSettings();
    if (response.isSuccess && response.data != null) {
      settingsState.setSettings(response.data!);
    }
    return response;
  }
}

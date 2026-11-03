import 'package:gestor_tareas_personales/domain/states/localization_state.dart';
import 'package:gestor_tareas_personales/domain/use_cases/settings/get_settings_use_case.dart';

class LoadUseCase {
  final LocalizationState localizationState;
  final GetSettingsUseCase getSettingsUseCase;

  LoadUseCase({
    required this.localizationState,
    required this.getSettingsUseCase,
  });

  Future<void> call() async {
    await localizationState.load();
    await getSettingsUseCase.getSettings();
  }
}

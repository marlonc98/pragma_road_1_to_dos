import 'package:gestor_tareas_personales/domain/states/localization_state.dart';

class LoadUseCase {
  final LocalizationState localizationState;

  LoadUseCase({required this.localizationState});

  Future<void> call() async {
    await localizationState.load();
  }
}

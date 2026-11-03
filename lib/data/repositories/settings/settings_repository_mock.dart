import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/settings_repository.dart';

class SettingsRepositoryMock extends SettingsRepository {
  SettingsEntity _settings = const SettingsEntity();

  @override
  Future<AsyncState<SettingsEntity>> getSettings() async =>
      AsyncState.success(data: _settings);

  @override
  Future<AsyncState<void>> saveSettings(SettingsEntity settings) async {
    _settings = settings;
    return AsyncState.success();
  }
}

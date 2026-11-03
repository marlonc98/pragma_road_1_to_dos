import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';

abstract class SettingsRepository {
  Future<AsyncState<SettingsEntity>> getSettings();
  Future<AsyncState<void>> saveSettings(SettingsEntity settings);
}

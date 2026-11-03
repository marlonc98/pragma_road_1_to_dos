import 'package:gestor_tareas_personales/data/repositories/settings/api/get_settings_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/settings/api/save_settings_api_impl.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl extends SettingsRepository {
  static const String autoSaveKey = 'sp_settings_auto_save';
  static const String requireEditModeKey = 'sp_settings_require_edit_mode';

  @override
  Future<AsyncState<SettingsEntity>> getSettings() async {
    try {
      return AsyncState.success(
        data: await getSettingsApiImpl(autoSaveKey, requireEditModeKey),
      );
    } catch (error) {
      return AsyncState.fromError(error);
    }
  }

  @override
  Future<AsyncState<void>> saveSettings(SettingsEntity settings) async {
    try {
      await saveSettingsApiImpl(autoSaveKey, requireEditModeKey, settings);
      return AsyncState.success();
    } catch (error) {
      return AsyncState.fromError(error);
    }
  }
}

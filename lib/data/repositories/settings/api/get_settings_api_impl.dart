import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsEntity> getSettingsApiImpl(
  String autoSaveKey,
  String requireEditModeKey,
) async {
  final prefs = await SharedPreferences.getInstance();
  const defaults = SettingsEntity();
  return SettingsEntity(
    autoSave: prefs.getBool(autoSaveKey) ?? defaults.autoSave,
    requireEditMode:
        prefs.getBool(requireEditModeKey) ?? defaults.requireEditMode,
  );
}

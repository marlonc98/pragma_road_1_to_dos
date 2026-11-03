import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveSettingsApiImpl(
  String autoSaveKey,
  String requireEditModeKey,
  SettingsEntity settings,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool(autoSaveKey, settings.autoSave);
  await prefs.setBool(requireEditModeKey, settings.requireEditMode);
}

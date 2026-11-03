import 'package:gestor_tareas_personales/data/repositories/note/api/note_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> deleteNoteApiImpl(
  String notePrefix,
  String pinnedNotesKey,
  String id,
) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(noteKey(notePrefix, id));
  final pinnedIds = prefs.getStringList(pinnedNotesKey) ?? [];
  if (pinnedIds.remove(id)) {
    await prefs.setStringList(pinnedNotesKey, pinnedIds);
  }
}

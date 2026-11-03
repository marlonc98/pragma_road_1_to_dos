import 'dart:convert';

import 'package:gestor_tareas_personales/data/repositories/note/api/note_storage.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<NoteEntity?> getNoteByIdApiImpl(
  String notePrefix,
  String pinnedNotesKey,
  String id,
) async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(noteKey(notePrefix, id));
  if (json == null) return null;
  final pinnedIds = prefs.getStringList(pinnedNotesKey) ?? [];
  return noteFromJson(jsonDecode(json), pinned: pinnedIds.contains(id));
}

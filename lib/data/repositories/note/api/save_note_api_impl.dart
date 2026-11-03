import 'dart:convert';

import 'package:gestor_tareas_personales/data/repositories/note/api/note_storage.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveNoteApiImpl(String notePrefix, NoteEntity note) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(
    noteKey(notePrefix, note.id),
    jsonEncode(noteToJson(note)),
  );
}

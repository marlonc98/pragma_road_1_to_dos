import 'dart:convert';

import 'package:gestor_tareas_personales/data/repositories/note/api/note_storage.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<NoteEntity>> getPinnedNotesApiImpl(
  String notePrefix,
  String pinnedNotesKey, {
  required int previewMaxLines,
  String? query,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final notes = <NoteEntity>[];
  for (final id in prefs.getStringList(pinnedNotesKey) ?? <String>[]) {
    final json = prefs.getString(noteKey(notePrefix, id));
    if (json == null) continue;
    final note = noteFromJson(jsonDecode(json), pinned: true);
    if (noteMatches(note, query)) notes.add(notePreview(note, previewMaxLines));
  }
  return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}

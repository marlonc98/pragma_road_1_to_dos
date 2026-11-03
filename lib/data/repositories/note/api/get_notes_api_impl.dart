import 'dart:convert';

import 'package:gestor_tareas_personales/data/repositories/note/api/note_storage.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<({List<NoteEntity> notes, int total})> getNotesApiImpl(
  String notePrefix,
  String pinnedNotesKey, {
  required int previewMaxLines,
  required int page,
  required int itemsPerPage,
  String? query,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final pinnedIds = prefs.getStringList(pinnedNotesKey) ?? [];

  final notes = <NoteEntity>[];
  for (final key in prefs.getKeys()) {
    if (!key.startsWith(noteKey(notePrefix, ''))) continue;
    final json = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
    if (pinnedIds.contains(json['id'])) continue;
    final note = noteFromJson(json, pinned: false);
    if (noteMatches(note, query)) notes.add(note);
  }
  notes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

  final pageNotes = notes
      .skip((page - 1) * itemsPerPage)
      .take(itemsPerPage)
      .map((note) => notePreview(note, previewMaxLines))
      .toList();
  return (notes: pageNotes, total: notes.length);
}

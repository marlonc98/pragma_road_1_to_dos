import 'dart:convert';

import 'package:gestor_tareas_personales/data/dto/note_dto.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/note_storage.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<List<NoteEntity>> getNotesApiImpl(
  String notePrefix,
  String pinnedNotesKey,
) async {
  final prefs = await SharedPreferences.getInstance();
  final pinnedIds = prefs.getStringList(pinnedNotesKey) ?? [];

  final notes = <NoteEntity>[];
  for (final key in prefs.getKeys()) {
    if (!key.startsWith(noteKey(notePrefix, ''))) continue;
    final dto = NoteDto.fromJson(
      jsonDecode(prefs.getString(key)!) as Map<String, dynamic>,
    );
    notes.add(dto.toEntity(pinned: pinnedIds.contains(dto.id)));
  }
  return notes..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
}

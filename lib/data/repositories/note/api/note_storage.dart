import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';

String noteKey(String notePrefix, String id) => '${notePrefix}_$id';

Map<String, dynamic> noteToJson(NoteEntity note) => {
  'id': note.id,
  'title': note.title,
  'content': note.content,
  'createdAt': note.createdAt.toIso8601String(),
  'updatedAt': note.updatedAt.toIso8601String(),
};

NoteEntity noteFromJson(Map<String, dynamic> json, {required bool pinned}) =>
    NoteEntity(
      id: json['id'] as String,
      title: json['title'] as String?,
      content: json['content'] as String?,
      pinned: pinned,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

bool noteMatches(NoteEntity note, String? query) {
  final search = query?.toLowerCase() ?? '';
  return search.isEmpty ||
      (note.title?.toLowerCase().contains(search) ?? false) ||
      (note.content?.toLowerCase().contains(search) ?? false);
}

NoteEntity notePreview(NoteEntity note, int maxLines) {
  final lines = note.content?.split('\n');
  if (lines == null || lines.length <= maxLines) return note;
  return note.copyWith(content: '${lines.take(maxLines).join('\n')}...');
}

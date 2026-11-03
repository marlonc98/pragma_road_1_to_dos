import 'package:gestor_tareas_personales/data/dto/task_dto.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';

/// Nota tal como se guarda en shared_preferences.
///
/// No incluye `pinned`: las fijadas se guardan aparte, como una lista de ids,
/// y el valor se indica al convertir con [toEntity].
class NoteDto {
  final String id;
  final String? title;
  final List<TaskDto> content;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NoteDto({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NoteDto.fromEntity(NoteEntity note) => NoteDto(
    id: note.id,
    title: note.title,
    content: note.content.map(TaskDto.fromEntity).toList(),
    createdAt: note.createdAt,
    updatedAt: note.updatedAt,
  );

  factory NoteDto.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    return NoteDto(
      id: id,
      title: json['title'] as String?,
      content: TaskDto.listFromJson(id, json['content']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'content': [for (final task in content) task.toJson()],
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  NoteEntity toEntity({required bool pinned}) => NoteEntity(
    id: id,
    title: title,
    content: [for (final task in content) task.toEntity()],
    pinned: pinned,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

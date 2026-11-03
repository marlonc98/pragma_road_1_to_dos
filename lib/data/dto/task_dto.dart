import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';

/// Tarea tal como se guarda dentro del JSON de una nota.
class TaskDto {
  final String id;
  final String content;
  final bool completed;

  const TaskDto({
    required this.id,
    required this.content,
    required this.completed,
  });

  factory TaskDto.fromEntity(TaskEntity task) =>
      TaskDto(id: task.id, content: task.content, completed: task.completed);

  factory TaskDto.fromJson(Map<String, dynamic> json) => TaskDto(
    id: json['id'] as String,
    content: json['content'] as String,
    completed: json['completed'] as bool? ?? false,
  );

  /// Lee el campo `content` de una nota, que es una lista de tareas o, en las
  /// notas guardadas antes de las tareas, un texto.
  static List<TaskDto> listFromJson(String noteId, Object? content) =>
      switch (content) {
        final List<dynamic> tasks => [
          for (final task in tasks.cast<Map<String, dynamic>>())
            TaskDto.fromJson(task),
        ],
        final String text => _listFromLegacyText(noteId, text),
        _ => [],
      };

  /// Cada renglón pasa a ser una tarea, y si estaba todo tachado, una tarea
  /// completada.
  static List<TaskDto> _listFromLegacyText(String noteId, String text) {
    const legacyListPrefix = '- ';
    const legacyStrikethrough = '~~';
    final lines = text.split('\n').map((line) => line.trim());
    return [
      for (final (index, line) in lines.where((l) => l.isNotEmpty).indexed)
        () {
          final content = line.startsWith(legacyListPrefix)
              ? line.substring(legacyListPrefix.length).trim()
              : line;
          return TaskDto(
            id: '${noteId}_$index',
            content: content.replaceAll(legacyStrikethrough, ''),
            completed:
                content.length > legacyStrikethrough.length * 2 &&
                content.startsWith(legacyStrikethrough) &&
                content.endsWith(legacyStrikethrough),
          );
        }(),
    ];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'completed': completed,
  };

  TaskEntity toEntity() =>
      TaskEntity(id: id, content: content, completed: completed);
}

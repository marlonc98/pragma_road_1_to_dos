/// Tarea de una lista. Cuando está [completed] se muestra tachada.
class TaskEntity {
  final String id;

  /// Texto de la tarea. Puede traer marcas Markdown (`**negrita**`, `_cursiva_`).
  String content;

  bool completed;

  TaskEntity({required this.id, required this.content, this.completed = false});
}

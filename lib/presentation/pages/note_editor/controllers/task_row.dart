import 'package:flutter/widgets.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/note_editing_controller.dart';

/// Estado de una tarea mientras se edita. Es una copia: lo que se cambia aquí no
/// toca la [TaskEntity] original hasta que se guarda.
class TaskRow {
  final String id;
  final FocusNode focusNode = FocusNode();

  /// El texto tal como está escrito en el campo.
  String draft;
  bool completed;

  TaskRow({required this.id, String text = '', this.completed = false})
    : draft = text;

  String get text => draft.trim();

  /// Si no tiene texto visible. Las marcas sueltas (`****`) no cuentan.
  bool get isBlank =>
      NoteEditingController.formattedSpan(text).toPlainText().trim().isEmpty;

  TaskEntity toEntity() =>
      TaskEntity(id: id, content: text, completed: completed);

  void dispose() => focusNode.dispose();
}

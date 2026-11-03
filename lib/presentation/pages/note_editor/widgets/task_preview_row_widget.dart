import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/note_editing_controller.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/task_row.dart';

/// Una tarea en la vista previa: solo se puede marcar.
class TaskPreviewRowWidget extends StatelessWidget {
  final TaskRow row;
  final VoidCallback onToggle;

  const TaskPreviewRowWidget({
    super.key,
    required this.row,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.5);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(value: row.completed, onChanged: (_) => onToggle()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
            child: Text.rich(
              NoteEditingController.formattedSpan(row.text),
              style: row.completed
                  ? baseStyle?.copyWith(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colorScheme.onSurfaceVariant,
                    )
                  : baseStyle,
            ),
          ),
        ),
      ],
    );
  }
}

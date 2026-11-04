import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/helpers/functions_helper.dart';
import 'package:gestor_tareas_personales/presentation/helpers/validators.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/task_row.dart';

/// Una tarea en edición. Avisa con [onEdited] cuando se deja de escribir.
class TaskRowWidget extends ConsumerStatefulWidget {
  final TaskRow row;
  final InputValidator validator;
  final VoidCallback onToggle;
  final VoidCallback onEdited;
  final VoidCallback onSubmitted;
  final VoidCallback onDelete;

  const TaskRowWidget({
    super.key,
    required this.row,
    required this.validator,
    required this.onToggle,
    required this.onEdited,
    required this.onSubmitted,
    required this.onDelete,
  });

  @override
  ConsumerState<TaskRowWidget> createState() => _TaskRowWidgetState();
}

class _TaskRowWidgetState extends ConsumerState<TaskRowWidget> {
  Timer? _editTimer;
  bool _hasError = false;

  /// El Form valida al construir el campo, y el check está fuera de él: se
  /// actualiza en el siguiente frame.
  String? _validate(String? text) {
    final error = widget.validator(text);
    if ((error != null) != _hasError) {
      _hasError = error != null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    return error;
  }

  void _handleChanged(String value) {
    // El texto se anota ya, para no perderlo si se guarda o se sale antes de
    // que se cumpla la espera
    widget.row.draft = value;
    _editTimer = FunctionsHelper.resetSearch(
      searchFunction: widget.onEdited,
      timer: _editTimer,
    );
  }

  @override
  void dispose() {
    _editTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.5);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: row.completed,
          isError: _hasError,
          onChanged: (_) => widget.onToggle(),
        ),
        Expanded(
          child: TextFormField(
            initialValue: row.draft,
            validator: _validate,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            focusNode: row.focusNode,
            maxLines: null,
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            autocorrect: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            inputFormatters: [
              FilteringTextInputFormatter.deny('\n', replacementString: ' '),
            ],
            onChanged: _handleChanged,
            // Sin esto, Enter le pasa el foco al siguiente botón
            onEditingComplete: () {},
            onFieldSubmitted: (_) => widget.onSubmitted(),
            style: row.completed
                ? baseStyle?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : baseStyle,
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              hintText: i18n(TextConstants.noteEditorTaskHint),
              hintStyle: WidgetStateTextStyle.resolveWith(
                (states) => (baseStyle ?? const TextStyle()).copyWith(
                  color: states.contains(WidgetState.error)
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          tooltip: i18n(TextConstants.noteEditorDeleteTask),
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';

enum UnsavedChangesOption { save, discard }

/// Devuelve null si el usuario cancela y se queda en el editor.
Future<UnsavedChangesOption?> showUnsavedChangesDialog(BuildContext context) {
  return showDialog<UnsavedChangesOption>(
    context: context,
    builder: (context) => const _UnsavedChangesDialog(),
  );
}

class _UnsavedChangesDialog extends ConsumerWidget {
  const _UnsavedChangesDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    final navigator = Navigator.of(context);
    return AlertDialog(
      title: Text(i18n(TextConstants.noteEditorUnsavedTitle)),
      actions: [
        TextButton(
          onPressed: navigator.pop,
          child: Text(i18n(TextConstants.noteEditorCancel)),
        ),
        TextButton(
          onPressed: () => navigator.pop(UnsavedChangesOption.discard),
          child: Text(i18n(TextConstants.noteEditorDiscard)),
        ),
        TextButton(
          onPressed: () => navigator.pop(UnsavedChangesOption.save),
          child: Text(i18n(TextConstants.noteEditorSave)),
        ),
      ],
    );
  }
}

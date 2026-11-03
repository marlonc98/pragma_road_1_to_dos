import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';

enum NoteOption { pin, delete }

Future<NoteOption?> showNoteOptionsBottomSheet(
  BuildContext context, {
  required NoteEntity note,
}) {
  return showModalBottomSheet<NoteOption>(
    context: context,
    showDragHandle: true,
    builder: (context) => _NoteOptionsBottomSheet(note: note),
  );
}

class _NoteOptionsBottomSheet extends ConsumerWidget {
  final NoteEntity note;
  const _NoteOptionsBottomSheet({required this.note});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    final errorColor = Theme.of(context).colorScheme.error;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              note.pinned ? Icons.push_pin : Icons.push_pin_outlined,
            ),
            title: Text(
              i18n(
                note.pinned
                    ? TextConstants.noteOptionUnpin
                    : TextConstants.noteOptionPin,
              ),
            ),
            onTap: () => Navigator.of(context).pop(NoteOption.pin),
          ),
          ListTile(
            leading: Icon(Icons.delete_outline, color: errorColor),
            title: Text(
              i18n(TextConstants.noteOptionDelete),
              style: TextStyle(color: errorColor),
            ),
            onTap: () => Navigator.of(context).pop(NoteOption.delete),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

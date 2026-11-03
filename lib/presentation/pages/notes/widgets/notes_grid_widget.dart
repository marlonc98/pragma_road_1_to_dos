import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/note_preview_widget.dart';

class NotesGridWidget extends StatelessWidget {
  final List<NoteEntity> notes;
  final ValueChanged<NoteEntity> onTap;
  final ValueChanged<NoteEntity> onLongPress;

  const NotesGridWidget({
    super.key,
    required this.notes,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildColumn(0)),
        const SizedBox(width: 8),
        Expanded(child: _buildColumn(1)),
      ],
    );
  }

  Widget _buildColumn(int column) {
    return Column(
      children: [
        for (var i = column; i < notes.length; i += 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: NotePreviewWidget(
              note: notes[i],
              onTap: () => onTap(notes[i]),
              onLongPress: () => onLongPress(notes[i]),
            ),
          ),
      ],
    );
  }
}

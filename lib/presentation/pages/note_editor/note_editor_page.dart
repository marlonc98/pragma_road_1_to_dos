import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page_screen.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page_view_model.dart';
import 'package:gestor_tareas_personales/presentation/core/stf_view_model_adapter.dart';

class NoteEditorPage extends StatefulWidget {
  static const String route = '/notes/editor';

  final NoteEntity? note;
  const NoteEditorPage({super.key, this.note});

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  @override
  Widget build(BuildContext context) {
    return StfViewModelAdapter(
      create: (ref) => NoteEditorPageViewModel(
        context: context,
        widget: widget,
        ref: ref,
        isMounted: () => mounted,
      ),
      builder: (context, viewModel) => NoteEditorPageScreen(vm: viewModel),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page_screen.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page_view_model.dart';
import 'package:gestor_tareas_personales/presentation/core/stf_view_model_adapter.dart';

class NotesPage extends StatefulWidget {
  static const String route = '/notes';
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  @override
  Widget build(BuildContext context) {
    return StfViewModelAdapter(
      create: (ref) => NotesPageViewModel(
        context: context,
        widget: widget,
        ref: ref,
        isMounted: () => mounted,
      ),
      builder: (context, viewModel) => NotesPageScreen(vm: viewModel),
    );
  }
}

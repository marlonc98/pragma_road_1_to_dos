import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/note_options_bottom_sheet.dart';
import 'package:gestor_tareas_personales/presentation/pages/settings/settings_page.dart';
import 'package:gestor_tareas_personales/presentation/core/view_model.dart';

class NotesPageViewModel extends ViewModel<NotesPage> {
  NotesPageViewModel({
    required super.context,
    required super.widget,
    required super.ref,
    required super.isMounted,
  }) {
    // El ViewModel se crea en initState, y un provider no se puede modificar
    // mientras se construye el árbol
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) handleLoadNotes();
    });
  }

  final TextEditingController searchController = TextEditingController();

  String get query => searchController.text.trim();

  /// Las notas que coinciden con la búsqueda.
  List<NoteEntity> visibleNotes(List<NoteEntity> notes) =>
      notes.where((note) => note.matches(query)).toList();

  Future<void> handleLoadNotes() =>
      ref.read(getNotesUseCaseProvider).getNotes();

  void handleSearchChanged(String _) => notifyListeners();

  void handleClearSearch() {
    searchController.clear();
    notifyListeners();
  }

  Future<void> handleOpenSettings() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.push(SettingsPage.route);
  }

  Future<void> handleCreateNote() => _openEditor(null);

  Future<void> handleOpenNote(NoteEntity note) => _openEditor(note);

  Future<void> _openEditor(NoteEntity? note) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.push(NoteEditorPage.route, extra: note);
  }

  Future<void> handleNoteOptions(NoteEntity note) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final option = await showNoteOptionsBottomSheet(context, note: note);
    if (option == null || !mounted) return;
    final response = switch (option) {
      NoteOption.pin => await ref.read(pinNoteUseCaseProvider).togglePin(note),
      NoteOption.delete =>
        await ref.read(deleteNoteUseCaseProvider).deleteNote(note.id),
    };
    if (!mounted) return;
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    if (!response.isSuccess) {
      _showMessage(i18n(response.error ?? ''));
      return;
    }
    if (option == NoteOption.delete) {
      _showMessage(i18n(TextConstants.noteDeleted));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

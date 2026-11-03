import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/note_options_bottom_sheet.dart';
import 'package:gestor_tareas_personales/presentation/core/view_model.dart';

class NotesPageViewModel extends ViewModel<NotesPage> {
  NotesPageViewModel({
    required super.context,
    required super.widget,
    required super.ref,
    required super.isMounted,
  }) {
    _loadPinnedNotes();
  }

  static const int _itemsPerPage = 20;

  final TextEditingController searchController = TextEditingController();
  Timer? _searchDebounce;
  int _pinnedRequest = 0;

  late final PagingController<int, NoteEntity> pagingController =
      PagingController(getNextPageKey: _getNextPageKey, fetchPage: _fetchPage);

  AsyncState<List<NoteEntity>> pinnedNotes =
      AsyncState<List<NoteEntity>>.loading();

  String get query => searchController.text.trim();

  Future<void> handleLoadNotes() async {
    pagingController.refresh();
    await _loadPinnedNotes();
  }

  void handleRetry() {
    pinnedNotes = AsyncState<List<NoteEntity>>.loading();
    notifyListeners();
    handleLoadNotes();
  }

  Future<void> _loadPinnedNotes() async {
    final request = ++_pinnedRequest;
    final response = await ref
        .read(getPinnedNotesUseCaseProvider)
        .getPinnedNotes(query: query);
    if (request != _pinnedRequest || !mounted) return;
    pinnedNotes = response;
    notifyListeners();
  }

  int? _getNextPageKey(PagingState<int, NoteEntity> state) {
    final lastPageLength = state.pages?.lastOrNull?.length;
    if (lastPageLength != null && lastPageLength < _itemsPerPage) return null;
    return state.nextIntPageKey;
  }

  Future<List<NoteEntity>> _fetchPage(int page) async {
    final response = await ref
        .read(getNotesUseCaseProvider)
        .getNotes(page: page, itemsPerPage: _itemsPerPage, query: query);
    if (!response.isSuccess) {
      final i18n = ref.read(localizationStateProvider.notifier).translate;
      throw i18n(response.error ?? ErrorsConstants.unknownError);
    }
    return response.data?.data ?? [];
  }

  void handleSearchChanged(String _) {
    notifyListeners();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), handleLoadNotes);
  }

  void handleClearSearch() {
    searchController.clear();
    handleSearchChanged('');
  }

  Future<void> handleCreateNote() => _openEditor(null);

  Future<void> handleOpenNote(NoteEntity note) => _openEditor(note);

  Future<void> _openEditor(NoteEntity? note) async {
    FocusManager.instance.primaryFocus?.unfocus();
    await context.push(NoteEditorPage.route, extra: note);
    if (mounted) await handleLoadNotes();
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
    await handleLoadNotes();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    pagingController.dispose();
    searchController.dispose();
    super.dispose();
  }
}

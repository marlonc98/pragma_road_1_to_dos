import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/presentation/constants/markdown_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/note_editing_controller.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page.dart';
import 'package:gestor_tareas_personales/presentation/core/view_model.dart';

enum SaveStatus { idle, saving, saved }

class NoteEditorPageViewModel extends ViewModel<NoteEditorPage> {
  static const Duration autosaveDelay = Duration(milliseconds: 800);

  NoteEditorPageViewModel({
    required super.context,
    required super.widget,
    required super.ref,
    required super.isMounted,
  }) {
    controller = NoteEditingController()..addListener(_onTextChanged);
    if (widget.note != null) _loadNote(widget.note!.id);
  }

  late final NoteEditingController controller;
  NoteEntity? _note;
  String _savedText = '';
  SaveStatus saveStatus = SaveStatus.idle;

  late bool isLoading = widget.note != null;

  Timer? _autosaveDebounce;

  Future<void> _saveQueue = Future.value();

  bool get isNewNote => widget.note == null;

  Future<void> _loadNote(String id) async {
    final response = await ref.read(getNotesUseCaseProvider).getNoteById(id);
    if (!mounted) return;
    if (!response.isSuccess) {
      final i18n = ref.read(localizationStateProvider.notifier).translate;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(i18n(response.error ?? ''))));
      // ignore: use_build_context_synchronously
      context.pop();
      return;
    }
    _note = response.data;
    _savedText = _noteToText(_note);
    controller.text = _savedText;
    isLoading = false;
    notifyListeners();
  }

  bool get _hasUnsavedChanges => controller.text != _savedText;

  void _onTextChanged() {
    if (!_hasUnsavedChanges) return;
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(autosaveDelay, _enqueueSave);
  }

  Future<void> _enqueueSave() {
    _saveQueue = _saveQueue.then((_) => _save());
    return _saveQueue;
  }

  Future<void> _save() async {
    final text = controller.text;
    if (text == _savedText) return;
    final parsed = _parseText(text);
    if (parsed.title == null && parsed.content == null) return;

    final now = DateTime.now();
    final note = NoteEntity(
      id: _note?.id ?? now.microsecondsSinceEpoch.toString(),
      title: parsed.title,
      content: parsed.content,
      pinned: _note?.pinned ?? false,
      createdAt: _note?.createdAt ?? now,
      updatedAt: now,
    );
    saveStatus = SaveStatus.saving;
    notifyListeners();
    final saveNoteUseCase = ref.read(saveNoteUseCaseProvider);
    final response = _note == null
        ? await saveNoteUseCase.addNote(note)
        : await saveNoteUseCase.updateNote(note);
    if (response.isSuccess) {
      _note = note;
      _savedText = text;
      saveStatus = SaveStatus.saved;
    } else {
      saveStatus = SaveStatus.idle;
      if (mounted) {
        final i18n = ref.read(localizationStateProvider.notifier).translate;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(i18n(response.error ?? ''))));
      }
    }
    notifyListeners();
  }

  Future<void> handleExit() async {
    _autosaveDebounce?.cancel();
    if (isLoading) {
      context.pop();
      return;
    }
    if (_hasUnsavedChanges) await _enqueueSave();
    await _saveQueue;
    final parsed = _parseText(controller.text);
    final isEmpty = parsed.title == null && parsed.content == null;
    if (isEmpty && _note != null) {
      await ref.read(deleteNoteUseCaseProvider).deleteNote(_note!.id);
    }
    if (mounted) {
      // ignore: use_build_context_synchronously
      context.pop();
    }
  }

  void handleBold() => controller.toggleFormat(MarkdownFormat.bold);

  void handleItalic() => controller.toggleFormat(MarkdownFormat.italic);

  void handleStrikethrough() =>
      controller.toggleFormat(MarkdownFormat.strikethrough);

  void handleList() {
    final text = controller.text;
    final selection = controller.selection;
    if (!selection.isValid) return;
    final lineStart = selection.start == 0
        ? 0
        : text.lastIndexOf('\n', selection.start - 1) + 1;
    const prefix = MarkdownConstants.listPrefix;
    final hasPrefix = text.startsWith(prefix, lineStart);
    final shift = hasPrefix ? -prefix.length : prefix.length;
    controller.value = TextEditingValue(
      text: hasPrefix
          ? text.replaceRange(lineStart, lineStart + prefix.length, '')
          : text.replaceRange(lineStart, lineStart, prefix),
      selection: TextSelection(
        baseOffset: max(lineStart, selection.baseOffset + shift),
        extentOffset: max(lineStart, selection.extentOffset + shift),
      ),
    );
  }

  ({String? title, String? content}) _parseText(String text) {
    final breakIndex = text.indexOf('\n');
    final title = breakIndex == -1 ? text : text.substring(0, breakIndex);
    final content = breakIndex == -1 ? '' : text.substring(breakIndex + 1);
    return (
      title: title.trim().isEmpty ? null : title.trim(),
      content: content.trim().isEmpty ? null : content.trimRight(),
    );
  }

  String _noteToText(NoteEntity? note) {
    if (note == null) return '';
    if (!note.hasContent) return note.title ?? '';
    return '${note.title ?? ''}\n${note.content}';
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    controller.dispose();
    super.dispose();
  }
}

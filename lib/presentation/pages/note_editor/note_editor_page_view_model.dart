import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';
import 'package:gestor_tareas_personales/presentation/helpers/validators.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/note_editing_controller.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/task_row.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/widgets/unsaved_changes_dialog.dart';
import 'package:gestor_tareas_personales/presentation/core/view_model.dart';

enum SaveStatus { idle, saving, saved }

class NoteEditorPageViewModel extends ViewModel<NoteEditorPage> {
  static const Duration autosaveDelay = Duration(milliseconds: 800);
  static const int maxTextLength = 100;

  NoteEditorPageViewModel({
    required super.context,
    required super.widget,
    required super.ref,
    required super.isMounted,
  }) {
    _note = widget.note;
    isEditing = _note == null || !_settings.requireEditMode;
    titleController.text = _note?.title ?? '';
    titleController.addListener(_onChanged);
    titleFocusNode.addListener(() {
      if (titleFocusNode.hasFocus) _activeController = titleController;
    });
    if (_note == null) {
      taskRows.add(_newRow());
    } else {
      taskRows.addAll(_note!.content.map(_rowFromTask));
    }
    _savedSnapshot = _snapshot();
  }

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final NoteEditingController titleController = NoteEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final List<TaskRow> taskRows = [];

  NoteEntity? _note;
  String _savedSnapshot = '';
  SaveStatus saveStatus = SaveStatus.idle;

  /// En la vista previa solo se ven las tareas y se pueden marcar.
  late bool isEditing;

  /// Sobre él actúa la barra de formato. Las tareas no tienen controller, así
  /// que con el foco en una tarea es null y la barra no hace nada.
  NoteEditingController? _activeController;

  Timer? _autosaveDebounce;

  Future<void> _saveQueue = Future.value();

  int _nextRowId = 0;

  SettingsEntity get _settings => ref.read(settingsStateProvider);

  bool get isNewNote => widget.note == null;

  String? get title => _title;

  /// Con el autoguardado y sin vista previa no hay nada que confirmar.
  bool get showSaveButton =>
      isEditing && (_settings.requireEditMode || !_settings.autoSave);

  TaskRow _newRow() => _watchRow(
    TaskRow(id: '${DateTime.now().microsecondsSinceEpoch}_${_nextRowId++}'),
  );

  TaskRow _rowFromTask(TaskEntity task) => _watchRow(
    TaskRow(id: task.id, text: task.content, completed: task.completed),
  );

  TaskRow _watchRow(TaskRow row) {
    row.focusNode.addListener(() {
      if (row.focusNode.hasFocus) _activeController = null;
    });
    return row;
  }

  String? get _title {
    final title = titleController.text.trim();
    return title.isEmpty ? null : title;
  }

  List<TaskEntity> get _tasks => [
    for (final row in taskRows)
      if (!row.isBlank) row.toEntity(),
  ];

  bool get _isEmpty => _title == null && _tasks.isEmpty;

  late final InputValidator _validateText = Validators.check(
    ref.read(localizationStateProvider.notifier).translate,
    required: true,
    maxLength: maxTextLength,
  );

  String? validateTitle(String? text) => _validateText(text);

  /// Las marcas sueltas (`****`) no cuentan como texto, igual que en [TaskRow].
  String? validateTask(String? text) => _validateText(
    NoteEditingController.formattedSpan(text ?? '').toPlainText(),
  );

  /// Si se puede guardar sin confirmar. Las filas vacías no cuentan: no se
  /// guardan.
  bool get _canAutoSave =>
      validateTitle(titleController.text) == null &&
      _tasks.every((task) => validateTask(task.content) == null);

  /// Valida el formulario y, si falla, lleva el foco al primer campo con error.
  bool _validateForm() {
    final isValid = formKey.currentState!.validate();
    if (!isValid) {
      final focusNode = validateTitle(titleController.text) != null
          ? titleFocusNode
          : taskRows
                .firstWhere((row) => validateTask(row.draft) != null)
                .focusNode;
      focusNode.requestFocus();
    }
    return isValid;
  }

  /// Lo que se guardaría ahora. Las filas vacías no cuentan: no se guardan.
  String _snapshot() => jsonEncode([
    _title,
    for (final task in _tasks) [task.id, task.content, task.completed],
  ]);

  bool get _hasUnsavedChanges => _snapshot() != _savedSnapshot;

  void _onChanged() {
    if (!_hasUnsavedChanges) return;
    if (saveStatus == SaveStatus.saved) {
      // "Guardado" ya no es cierto: hay cambios sin guardar
      saveStatus = SaveStatus.idle;
      notifyListeners();
    }
    if (_settings.autoSave) {
      _autosaveDebounce?.cancel();
      _autosaveDebounce = Timer(autosaveDelay, _enqueueSave);
    }
  }

  Future<void> _enqueueSave() {
    _saveQueue = _saveQueue.then((_) => _save());
    return _saveQueue;
  }

  Future<void> _save() async {
    final snapshot = _snapshot();
    if (snapshot == _savedSnapshot) return;
    final title = _title;
    final tasks = _tasks;
    // Al editar se respetan las validaciones. En la vista previa solo se marcan
    // tareas, y las listas viejas sin título también deben poder guardarlo.
    if (isEditing ? !_canAutoSave : _isEmpty) return;

    final now = DateTime.now();
    final note = NoteEntity(
      id: _note?.id ?? now.microsecondsSinceEpoch.toString(),
      title: title,
      content: tasks,
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
      _savedSnapshot = snapshot;
      saveStatus = SaveStatus.saved;
    } else {
      saveStatus = SaveStatus.idle;
      if (mounted) _showMessage(response.error ?? '');
    }
    notifyListeners();
  }

  void _showMessage(String keyText) {
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(i18n(keyText))));
  }

  void handleEdit() {
    isEditing = true;
    notifyListeners();
  }

  Future<void> handleSave() async {
    _autosaveDebounce?.cancel();
    if (!_validateForm()) return;
    await _enqueueSave();
    if (!mounted || _hasUnsavedChanges || !_settings.requireEditMode) return;
    FocusManager.instance.primaryFocus?.unfocus();
    isEditing = false;
    notifyListeners();
  }

  Future<void> handleExit() async {
    _autosaveDebounce?.cancel();
    // Con autoguardado solo se pregunta si hay errores que impiden guardar
    final mustConfirm =
        isEditing &&
        _hasUnsavedChanges &&
        (!_settings.autoSave || (!_canAutoSave && !_isEmpty));
    if (mustConfirm) {
      final option = await showUnsavedChangesDialog(context);
      if (option == null || !mounted) return;
      if (option == UnsavedChangesOption.discard) {
        // ignore: use_build_context_synchronously
        context.pop();
        return;
      }
      if (!_validateForm()) return;
    }
    if (_hasUnsavedChanges) await _enqueueSave();
    await _saveQueue;
    // Si no se pudo guardar, el usuario decide otra vez en vez de perderlo
    if (mustConfirm && _hasUnsavedChanges && !_isEmpty) return;
    if (_isEmpty && _note != null) {
      await ref.read(deleteNoteUseCaseProvider).deleteNote(_note!.id);
    }
    if (mounted) {
      // ignore: use_build_context_synchronously
      context.pop();
    }
  }

  void handleBold() => _activeController?.toggleFormat(MarkdownFormat.bold);

  void handleItalic() => _activeController?.toggleFormat(MarkdownFormat.italic);

  void handleToggleTask(TaskRow row) {
    row.completed = !row.completed;
    notifyListeners();
    if (isEditing) {
      _onChanged();
    } else {
      // En la vista previa no hay botón de guardar
      _enqueueSave();
    }
  }

  void handleTaskEdited() => _onChanged();

  void handleAddTask() => _insertRowAt(taskRows.length);

  void handleTitleSubmitted() {
    if (taskRows.isEmpty) {
      handleAddTask();
    } else {
      taskRows.first.focusNode.requestFocus();
    }
  }

  /// Enter en una tarea crea otra debajo. En una vacía no hace nada, para no
  /// llenar la lista de filas vacías.
  void handleTaskSubmitted(TaskRow row) {
    if (row.isBlank) return;
    _insertRowAt(taskRows.indexOf(row) + 1);
  }

  void handleDeleteTask(TaskRow row) {
    taskRows.remove(row);
    notifyListeners();
    _onChanged();
    // El TextField sigue montado hasta el próximo frame
    WidgetsBinding.instance.addPostFrameCallback((_) => row.dispose());
  }

  void _insertRowAt(int index) {
    final row = _newRow();
    taskRows.insert(index, row);
    notifyListeners();
    // El nodo aún no está en el árbol hasta el próximo frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) row.focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    titleController.dispose();
    titleFocusNode.dispose();
    for (final row in taskRows) {
      row.dispose();
    }
    super.dispose();
  }
}

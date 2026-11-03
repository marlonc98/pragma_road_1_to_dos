import 'package:gestor_tareas_personales/data/repositories/note/api/count_pinned_notes_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/delete_note_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/get_note_by_id_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/get_notes_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/get_pinned_notes_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/save_note_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/set_pinned_api_impl.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/core/search_result.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class NoteRepositoryImpl extends NoteRepository {
  static const String notePrefix = 'sp_note';

  static const String pinnedNotesKey = 'sp_pinned_notes';

  static const int previewMaxLines = 10;

  @override
  Future<AsyncState<void>> addNote(NoteEntity note) =>
      _run(() => saveNoteApiImpl(notePrefix, note));

  @override
  Future<AsyncState<void>> updateNote(NoteEntity note) =>
      _run(() => saveNoteApiImpl(notePrefix, note));

  @override
  Future<AsyncState<void>> deleteNote(String id) =>
      _run(() => deleteNoteApiImpl(notePrefix, pinnedNotesKey, id));

  @override
  Future<AsyncState<List<NoteEntity>>> getPinnedNotes({
    String? query,
  }) => _run(
    () => getPinnedNotesApiImpl(
      notePrefix,
      pinnedNotesKey,
      previewMaxLines: previewMaxLines,
      query: query,
    ),
  );

  @override
  Future<AsyncState<SearchResult<NoteEntity>>> getNotes({
    required int page,
    required int itemsPerPage,
    String? query,
  }) => _run(() async {
    final result = await getNotesApiImpl(
      notePrefix,
      pinnedNotesKey,
      previewMaxLines: previewMaxLines,
      page: page,
      itemsPerPage: itemsPerPage,
      query: query,
    );
    return SearchResult(
      currentPage: page,
      totalItems: result.total,
      data: result.notes,
      itemsPerPage: itemsPerPage,
      lastpage: (result.total / itemsPerPage).ceil(),
    );
  });

  @override
  Future<AsyncState<NoteEntity>> getNoteById(String id) async {
    final response = await _run(
      () => getNoteByIdApiImpl(notePrefix, pinnedNotesKey, id),
    );
    if (response.isSuccess && response.data == null) {
      return AsyncState.fromError(ErrorsConstants.noteNotFound);
    }
    return response.map((note) => note!);
  }

  @override
  Future<AsyncState<void>> setPinned(String id, bool pinned) =>
      _run(() => setPinnedApiImpl(pinnedNotesKey, id, pinned));

  @override
  Future<AsyncState<int>> countPinnedNotes() =>
      _run(() => countPinnedNotesApiImpl(pinnedNotesKey));

  Future<AsyncState<T>> _run<T>(Future<T> Function() call) async {
    try {
      return AsyncState.success(data: await call());
    } catch (error) {
      return AsyncState.fromError(error);
    }
  }
}

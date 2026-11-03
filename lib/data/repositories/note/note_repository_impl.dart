import 'package:gestor_tareas_personales/data/repositories/note/api/count_pinned_notes_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/delete_note_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/get_notes_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/save_note_api_impl.dart';
import 'package:gestor_tareas_personales/data/repositories/note/api/set_pinned_api_impl.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class NoteRepositoryImpl extends NoteRepository {
  static const String notePrefix = 'sp_note';

  static const String pinnedNotesKey = 'sp_pinned_notes';

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
  Future<AsyncState<List<NoteEntity>>> getNotes() =>
      _run(() => getNotesApiImpl(notePrefix, pinnedNotesKey));

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

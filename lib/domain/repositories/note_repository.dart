import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/core/search_result.dart';

abstract class NoteRepository {
  Future<AsyncState<void>> addNote(NoteEntity note);
  Future<AsyncState<void>> updateNote(NoteEntity note);
  Future<AsyncState<void>> deleteNote(String id);

  Future<AsyncState<List<NoteEntity>>> getPinnedNotes({
    String? query,
  });

  Future<AsyncState<SearchResult<NoteEntity>>> getNotes({
    required int page,
    required int itemsPerPage,
    String? query,
  });

  Future<AsyncState<NoteEntity>> getNoteById(String id);

  Future<AsyncState<void>> setPinned(String id, bool pinned);
  Future<AsyncState<int>> countPinnedNotes();
}

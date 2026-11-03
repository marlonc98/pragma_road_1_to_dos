import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';

abstract class NoteRepository {
  Future<AsyncState<void>> addNote(NoteEntity note);
  Future<AsyncState<void>> updateNote(NoteEntity note);
  Future<AsyncState<void>> deleteNote(String id);

  /// Todas las notas, completas, de la más reciente a la más antigua.
  Future<AsyncState<List<NoteEntity>>> getNotes();

  Future<AsyncState<void>> setPinned(String id, bool pinned);
  Future<AsyncState<int>> countPinnedNotes();
}

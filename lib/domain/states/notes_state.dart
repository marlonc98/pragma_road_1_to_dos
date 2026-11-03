import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';

/// Notas cargadas en memoria. Los casos de uso lo actualizan después de hablar
/// con el repositorio, y la UI solo lo observa.
abstract class NotesState {
  void setLoading();
  void setNotes(AsyncState<List<NoteEntity>> notes);
  void upsertNote(NoteEntity note);
  void removeNote(String id);
  void setPinned(String id, bool pinned);
}

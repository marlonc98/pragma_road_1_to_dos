import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/states/notes_state.dart';

class NotesStateImpl extends Notifier<AsyncState<List<NoteEntity>>>
    implements NotesState {
  @override
  AsyncState<List<NoteEntity>> build() => AsyncState.loading();

  List<NoteEntity> get _notes => state.data ?? const [];

  @override
  void setLoading() {
    // Al recargar, la lista sigue a la vista hasta que lleguen los datos nuevos
    if (state.data != null) return;
    state = state.copyWith(status: PetitionStatus.loading);
  }

  @override
  void setNotes(AsyncState<List<NoteEntity>> notes) => state = notes;

  @override
  void upsertNote(NoteEntity note) {
    state = state.copyWith(
      data: [
        note,
        for (final other in _notes)
          if (other.id != note.id) other,
      ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  @override
  void removeNote(String id) {
    state = state.copyWith(
      data: [
        for (final note in _notes)
          if (note.id != id) note,
      ],
    );
  }

  @override
  void setPinned(String id, bool pinned) {
    state = state.copyWith(
      data: [
        for (final note in _notes)
          note.id == id ? note.copyWith(pinned: pinned) : note,
      ],
    );
  }
}

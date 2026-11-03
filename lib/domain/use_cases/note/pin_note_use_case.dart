import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';
import 'package:gestor_tareas_personales/domain/states/notes_state.dart';

class PinNoteUseCase {
  static const int maxPinnedNotes = 5;

  final NoteRepository noteRepository;
  final NotesState notesState;

  PinNoteUseCase({required this.noteRepository, required this.notesState});

  Future<AsyncState<void>> togglePin(NoteEntity note) async {
    if (!note.pinned) {
      final pinnedCount = await noteRepository.countPinnedNotes();
      if (!pinnedCount.isSuccess) return pinnedCount;
      if ((pinnedCount.data ?? 0) >= maxPinnedNotes) {
        return AsyncState.fromError(ErrorsConstants.maxPinnedNotes);
      }
    }
    final response = await noteRepository.setPinned(note.id, !note.pinned);
    if (response.isSuccess) notesState.setPinned(note.id, !note.pinned);
    return response;
  }
}

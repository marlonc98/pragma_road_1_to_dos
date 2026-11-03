import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class SaveNoteUseCase {
  final NoteRepository noteRepository;

  SaveNoteUseCase({required this.noteRepository});

  Future<AsyncState<void>> addNote(NoteEntity note) async {
    if (note.isEmpty) {
      return AsyncState.fromError(ErrorsConstants.emptyNote);
    }
    return noteRepository.addNote(note);
  }

  Future<AsyncState<void>> updateNote(NoteEntity note) async {
    if (note.isEmpty) {
      return AsyncState.fromError(ErrorsConstants.emptyNote);
    }
    return noteRepository.updateNote(note);
  }
}

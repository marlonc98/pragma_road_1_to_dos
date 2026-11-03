import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';
import 'package:gestor_tareas_personales/domain/states/notes_state.dart';

class SaveNoteUseCase {
  final NoteRepository noteRepository;
  final NotesState notesState;

  SaveNoteUseCase({required this.noteRepository, required this.notesState});

  Future<AsyncState<void>> addNote(NoteEntity note) async {
    if (note.isEmpty) {
      return AsyncState.fromError(ErrorsConstants.emptyNote);
    }
    final response = await noteRepository.addNote(note);
    if (response.isSuccess) notesState.upsertNote(note);
    return response;
  }

  Future<AsyncState<void>> updateNote(NoteEntity note) async {
    if (note.isEmpty) {
      return AsyncState.fromError(ErrorsConstants.emptyNote);
    }
    final response = await noteRepository.updateNote(note);
    if (response.isSuccess) notesState.upsertNote(note);
    return response;
  }
}

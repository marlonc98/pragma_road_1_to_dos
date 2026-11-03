import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';
import 'package:gestor_tareas_personales/domain/states/notes_state.dart';

class DeleteNoteUseCase {
  final NoteRepository noteRepository;
  final NotesState notesState;

  DeleteNoteUseCase({required this.noteRepository, required this.notesState});

  Future<AsyncState<void>> deleteNote(String id) async {
    final response = await noteRepository.deleteNote(id);
    if (response.isSuccess) notesState.removeNote(id);
    return response;
  }
}

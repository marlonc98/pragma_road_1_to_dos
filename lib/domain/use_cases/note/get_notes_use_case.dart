import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';
import 'package:gestor_tareas_personales/domain/states/notes_state.dart';

class GetNotesUseCase {
  final NoteRepository noteRepository;
  final NotesState notesState;

  GetNotesUseCase({required this.noteRepository, required this.notesState});

  Future<AsyncState<List<NoteEntity>>> getNotes() async {
    notesState.setLoading();
    final response = await noteRepository.getNotes();
    notesState.setNotes(response);
    return response;
  }
}

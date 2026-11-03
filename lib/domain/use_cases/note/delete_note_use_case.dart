import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class DeleteNoteUseCase {
  final NoteRepository noteRepository;

  DeleteNoteUseCase({required this.noteRepository});

  Future<AsyncState<void>> deleteNote(String id) =>
      noteRepository.deleteNote(id);
}

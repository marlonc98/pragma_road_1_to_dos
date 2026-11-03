import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/core/search_result.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class GetNotesUseCase {
  final NoteRepository noteRepository;

  GetNotesUseCase({required this.noteRepository});

  Future<AsyncState<SearchResult<NoteEntity>>> getNotes({
    required int page,
    required int itemsPerPage,
    String? query,
  }) => noteRepository.getNotes(
    page: page,
    itemsPerPage: itemsPerPage,
    query: query?.trim(),
  );

  Future<AsyncState<NoteEntity>> getNoteById(String id) =>
      noteRepository.getNoteById(id);
}

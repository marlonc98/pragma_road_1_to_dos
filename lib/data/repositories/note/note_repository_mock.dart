import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

class NoteRepositoryMock extends NoteRepository {
  final Duration _delay = const Duration(milliseconds: 400);
  final List<NoteEntity> _fakeNotes = [];

  @override
  Future<AsyncState<void>> addNote(NoteEntity note) async {
    await Future.delayed(_delay);
    _fakeNotes.add(note);
    return AsyncState.success();
  }

  @override
  Future<AsyncState<void>> updateNote(NoteEntity note) async {
    await Future.delayed(_delay);
    final index = _fakeNotes.indexWhere((element) => element.id == note.id);
    if (index == -1) return AsyncState.fromError(Exception());
    _fakeNotes[index] = note;
    return AsyncState.success();
  }

  @override
  Future<AsyncState<void>> deleteNote(String id) async {
    await Future.delayed(_delay);
    _fakeNotes.removeWhere((element) => element.id == id);
    return AsyncState.success();
  }

  @override
  Future<AsyncState<List<NoteEntity>>> getNotes() async {
    await Future.delayed(_delay);
    return AsyncState.success(
      data: [..._fakeNotes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  @override
  Future<AsyncState<void>> setPinned(String id, bool pinned) async {
    await Future.delayed(_delay);
    final index = _fakeNotes.indexWhere((element) => element.id == id);
    if (index == -1) {
      return AsyncState.fromError(ErrorsConstants.noteNotFound);
    }
    _fakeNotes[index] = _fakeNotes[index].copyWith(pinned: pinned);
    return AsyncState.success();
  }

  @override
  Future<AsyncState<int>> countPinnedNotes() async {
    return AsyncState.success(
      data: _fakeNotes.where((note) => note.pinned).length,
    );
  }
}

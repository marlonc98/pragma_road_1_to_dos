import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_mock.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';

NoteEntity note(String id) => NoteEntity(
  id: id,
  title: 'Lista $id',
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  late NoteRepositoryMock repository;

  setUp(() => repository = NoteRepositoryMock());

  test('empieza sin notas', () async {
    final response = await repository.getNotes();
    expect(response.isSuccess, isTrue);
    expect(response.data, isEmpty);
    expect((await repository.countPinnedNotes()).data, 0);
  });

  test('cada instancia tiene sus propias notas', () async {
    await repository.addNote(note('1'));
    expect((await NoteRepositoryMock().getNotes()).data, isEmpty);
  });

  test('editar o fijar una nota que no existe da error', () async {
    expect((await repository.updateNote(note('1'))).isError, isTrue);
    final pinned = await repository.setPinned('1', true);
    expect(pinned.isError, isTrue);
    expect(pinned.error, ErrorsConstants.noteNotFound);
  });

  test('borrar una nota que no existe no da error', () async {
    expect((await repository.deleteNote('1')).isSuccess, isTrue);
  });

  test('crear, editar, fijar y borrar', () async {
    await repository.addNote(note('1'));
    await repository.updateNote(note('1').copyWith(title: 'Editada'));
    await repository.setPinned('1', true);
    final saved = (await repository.getNotes()).data!.single;
    expect(saved.title, 'Editada');
    expect(saved.pinned, isTrue);

    await repository.deleteNote('1');
    expect((await repository.getNotes()).data, isEmpty);
  });
}

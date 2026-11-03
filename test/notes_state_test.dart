import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

NoteEntity note(String id, {int day = 1}) => NoteEntity(
  id: id,
  title: 'Lista $id',
  createdAt: DateTime(2026, 1, day),
  updatedAt: DateTime(2026, 1, day),
);

class _FailingRepository extends NoteRepositoryImpl {
  @override
  Future<AsyncState<void>> updateNote(NoteEntity note) async =>
      AsyncState.fromError(Exception());

  @override
  Future<AsyncState<void>> deleteNote(String id) async =>
      AsyncState.fromError(Exception());

  @override
  Future<AsyncState<List<NoteEntity>>> getNotes() async =>
      AsyncState.fromError(Exception());
}

void main() {
  late ProviderContainer container;

  ProviderContainer createContainer(NoteRepository repository) {
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  List<String> stateIds() =>
      container.read(notesStateProvider).data!.map((note) => note.id).toList();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    container = createContainer(NoteRepositoryImpl());
  });

  test('empieza cargando y getNotes lo llena', () async {
    await NoteRepositoryImpl().addNote(note('1'));
    expect(container.read(notesStateProvider).isLoading, isTrue);

    await container.read(getNotesUseCaseProvider).getNotes();
    expect(container.read(notesStateProvider).isSuccess, isTrue);
    expect(stateIds(), ['1']);
  });

  test('al recargar con datos, no vuelve al estado de carga', () async {
    await container.read(getNotesUseCaseProvider).getNotes();
    container.read(notesStateProvider.notifier).setLoading();
    expect(container.read(notesStateProvider).isLoading, isFalse);
  });

  test('crear y editar actualizan la lista sin volver a cargarla', () async {
    await container.read(getNotesUseCaseProvider).getNotes();
    final save = container.read(saveNoteUseCaseProvider);

    await save.addNote(note('1', day: 1));
    await save.addNote(note('2', day: 2));
    expect(stateIds(), ['2', '1']);

    final edited = note('1', day: 3).copyWith(
      content: [TaskEntity(id: 'a', content: 'Pan', completed: true)],
    );
    await save.updateNote(edited);
    expect(stateIds(), ['1', '2']);
    final first = container.read(notesStateProvider).data!.first;
    expect(first.content.single.completed, isTrue);
  });

  test('borrar y fijar actualizan la lista', () async {
    await container.read(getNotesUseCaseProvider).getNotes();
    final save = container.read(saveNoteUseCaseProvider);
    await save.addNote(note('1', day: 1));
    await save.addNote(note('2', day: 2));

    await container.read(pinNoteUseCaseProvider).togglePin(note('1'));
    final notes = container.read(notesStateProvider).data!;
    expect(notes.singleWhere((note) => note.id == '1').pinned, isTrue);

    await container.read(deleteNoteUseCaseProvider).deleteNote('2');
    expect(stateIds(), ['1']);
  });

  test('si el repositorio falla, el estado no cambia', () async {
    final repository = NoteRepositoryImpl();
    await repository.addNote(note('1'));
    await container.read(getNotesUseCaseProvider).getNotes();

    final failing = createContainer(_FailingRepository());
    failing
        .read(notesStateProvider.notifier)
        .setNotes(container.read(notesStateProvider));

    final updated = note('1', day: 5);
    await failing.read(saveNoteUseCaseProvider).updateNote(updated);
    await failing.read(deleteNoteUseCaseProvider).deleteNote('1');

    final notes = failing.read(notesStateProvider).data!;
    expect(notes.single.updatedAt, DateTime(2026, 1, 1));
  });

  test('un fallo al cargar queda en el estado como error', () async {
    final failing = createContainer(_FailingRepository());
    await failing.read(getNotesUseCaseProvider).getNotes();
    expect(failing.read(notesStateProvider).isError, isTrue);
  });
}

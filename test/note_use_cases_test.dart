import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

NoteEntity note(String id, {String? title = 'Lista', bool pinned = false}) =>
    NoteEntity(
      id: id,
      title: title,
      pinned: pinned,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

class _FakeRepository extends NoteRepository {
  List<NoteEntity> notes = [];
  int pinnedCount = 0;
  bool failAll = false;
  bool failCount = false;
  int writes = 0;

  AsyncState<T> _result<T>({T? data}) => failAll
      ? AsyncState<T>.fromError(ErrorsConstants.unknownError)
      : AsyncState<T>.success(data: data);

  AsyncState<void> _write() {
    writes++;
    return _result();
  }

  @override
  Future<AsyncState<void>> addNote(NoteEntity note) async => _write();
  @override
  Future<AsyncState<void>> updateNote(NoteEntity note) async => _write();
  @override
  Future<AsyncState<void>> deleteNote(String id) async => _write();
  @override
  Future<AsyncState<void>> setPinned(String id, bool pinned) async => _write();
  @override
  Future<AsyncState<List<NoteEntity>>> getNotes() async => _result(data: notes);
  @override
  Future<AsyncState<int>> countPinnedNotes() async => failCount
      ? AsyncState<int>.fromError(ErrorsConstants.unknownError)
      : AsyncState<int>.success(data: pinnedCount);
}

void main() {
  late _FakeRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = _FakeRepository();
    container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  AsyncState<List<NoteEntity>> state() => container.read(notesStateProvider);

  Future<void> load(List<NoteEntity> notes) async {
    repository.notes = notes;
    await container.read(getNotesUseCaseProvider).getNotes();
  }

  group('GetNotesUseCase', () {
    test('sin notas queda en éxito con una lista vacía, no en null', () async {
      final response = await container.read(getNotesUseCaseProvider).getNotes();
      expect(response.isSuccess, isTrue);
      expect(response.data, isEmpty);
      expect(state().isSuccess, isTrue);
      expect(state().data, isEmpty);
    });

    test('un error queda en el estado', () async {
      repository.failAll = true;
      final response = await container.read(getNotesUseCaseProvider).getNotes();
      expect(response.isError, isTrue);
      expect(state().isError, isTrue);
      expect(state().error, ErrorsConstants.unknownError);
    });

    test('reintentar tras un error carga los datos', () async {
      repository.failAll = true;
      await load([note('1')]);
      repository.failAll = false;
      await load([note('1')]);
      expect(state().isSuccess, isTrue);
      expect(state().data, hasLength(1));
    });
  });

  group('SaveNoteUseCase', () {
    final emptyNotes = {
      'sin título ni tareas': note('1', title: null),
      'título vacío': note('1', title: ''),
      'título de espacios': note('1', title: '   '),
      'tareas vacías': NoteEntity(
        id: '1',
        content: [TaskEntity(id: 'a', content: '  ')],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      ),
    };

    emptyNotes.forEach((name, empty) {
      test('$name: rechaza crear y editar sin tocar el repositorio', () async {
        await load([]);
        final useCase = container.read(saveNoteUseCaseProvider);
        for (final response in [
          await useCase.addNote(empty),
          await useCase.updateNote(empty),
        ]) {
          expect(response.isError, isTrue);
          expect(response.error, ErrorsConstants.emptyNote);
        }
        expect(repository.writes, 0);
        expect(state().data, isEmpty);
      });
    });

    test('crear agrega al estado, y editar reemplaza sin duplicar', () async {
      await load([]);
      final useCase = container.read(saveNoteUseCaseProvider);
      await useCase.addNote(note('1', title: 'Original'));
      await useCase.updateNote(note('1', title: 'Editada'));
      expect(state().data!.single.title, 'Editada');
    });

    test('si el repositorio falla, el estado no cambia', () async {
      await load([note('1', title: 'Original')]);
      repository.failAll = true;
      final useCase = container.read(saveNoteUseCaseProvider);
      expect((await useCase.addNote(note('2'))).isError, isTrue);
      expect(
        (await useCase.updateNote(note('1', title: 'Editada'))).isError,
        isTrue,
      );
      expect(state().data!.single.title, 'Original');
    });
  });

  group('DeleteNoteUseCase', () {
    test('un id que no existe no cambia la lista', () async {
      await load([note('1')]);
      final response = await container
          .read(deleteNoteUseCaseProvider)
          .deleteNote('nada');
      expect(response.isSuccess, isTrue);
      expect(state().data, hasLength(1));
    });

    test('borrar en una lista vacía la deja vacía', () async {
      await load([]);
      await container.read(deleteNoteUseCaseProvider).deleteNote('1');
      expect(state().data, isEmpty);
    });

    test('si el repositorio falla, la nota sigue', () async {
      await load([note('1')]);
      repository.failAll = true;
      final response = await container
          .read(deleteNoteUseCaseProvider)
          .deleteNote('1');
      expect(response.isError, isTrue);
      expect(state().data, hasLength(1));
    });
  });

  group('PinNoteUseCase', () {
    test('fijar y soltar actualizan el estado', () async {
      await load([note('1')]);
      final useCase = container.read(pinNoteUseCaseProvider);
      await useCase.togglePin(note('1'));
      expect(state().data!.single.pinned, isTrue);
      await useCase.togglePin(note('1', pinned: true));
      expect(state().data!.single.pinned, isFalse);
    });

    test('si falla el conteo, no fija', () async {
      await load([note('1')]);
      repository.failCount = true;
      final response = await container
          .read(pinNoteUseCaseProvider)
          .togglePin(note('1'));
      expect(response.isError, isTrue);
      expect(repository.writes, 0);
      expect(state().data!.single.pinned, isFalse);
    });

    test('en el límite no fija otra, pero sí deja soltar', () async {
      await load([note('1'), note('2', pinned: true)]);
      repository.pinnedCount = 5;
      final useCase = container.read(pinNoteUseCaseProvider);

      final rejected = await useCase.togglePin(note('1'));
      expect(rejected.error, ErrorsConstants.maxPinnedNotes);

      final released = await useCase.togglePin(note('2', pinned: true));
      expect(released.isSuccess, isTrue);
    });

    test('si falla al guardar, el estado no cambia', () async {
      await load([note('1')]);
      repository.failAll = true;
      final response = await container
          .read(pinNoteUseCaseProvider)
          .togglePin(note('1'));
      expect(response.isError, isTrue);
      expect(state().data!.single.pinned, isFalse);
    });
  });

  group('estado con ids que no existen', () {
    test('quitar o fijar no cambia nada', () async {
      await load([note('1')]);
      final notifier = container.read(notesStateProvider.notifier);
      notifier.removeNote('nada');
      notifier.setPinned('nada', true);
      expect(state().data!.single.id, '1');
      expect(state().data!.single.pinned, isFalse);
    });

    test('en un estado sin datos, quitar o fijar deja una lista vacía', () {
      final notifier = container.read(notesStateProvider.notifier);
      notifier.removeNote('nada');
      notifier.setPinned('nada', true);
      expect(state().data, isEmpty);
    });
  });
}

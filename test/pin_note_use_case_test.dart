import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_mock.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/pin_note_use_case.dart';

void main() {
  test('no permite fijar más de 5 notas', () async {
    final repository = NoteRepositoryMock();
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final useCase = container.read(pinNoteUseCaseProvider);

    final notes = [
      for (var i = 0; i <= PinNoteUseCase.maxPinnedNotes; i++)
        NoteEntity(
          id: '$i',
          title: 'Lista $i',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
    ];
    for (final note in notes) {
      await repository.addNote(note);
    }

    for (var i = 0; i < PinNoteUseCase.maxPinnedNotes; i++) {
      expect((await useCase.togglePin(notes[i])).isSuccess, isTrue);
    }
    expect((await repository.countPinnedNotes()).data, 5);

    final response = await useCase.togglePin(notes.last);
    expect(response.isError, isTrue);
    expect(response.error, ErrorsConstants.maxPinnedNotes);
    expect((await repository.countPinnedNotes()).data, 5);
  });
}

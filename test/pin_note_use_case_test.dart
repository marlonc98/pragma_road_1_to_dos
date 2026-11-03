import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_mock.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/use_cases/note/pin_note_use_case.dart';

void main() {
  test('no permite fijar más de 5 notas', () async {
    final repository = NoteRepositoryMock();
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final useCase = container.read(pinNoteUseCaseProvider);

    final unpinned = (await repository.getNotes()).data!
        .where((note) => !note.pinned)
        .toList();
    final pinnedBefore = (await repository.countPinnedNotes()).data!;

    for (var i = 0; i < PinNoteUseCase.maxPinnedNotes - pinnedBefore; i++) {
      expect((await useCase.togglePin(unpinned[i])).isSuccess, isTrue);
    }
    expect((await repository.countPinnedNotes()).data, 5);

    final response = await useCase.togglePin(unpinned.last);
    expect(response.isError, isTrue);
    expect(response.error, ErrorsConstants.maxPinnedNotes);
    expect((await repository.countPinnedNotes()).data, 5);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpIntegrationTests();

  testWidgets('fijar y dejar de fijar', (tester) async {
    await startApp(tester);
    await createList(tester, 'Mercado');
    await createList(tester, 'Trabajo');
    expect(find.text('FIJADAS'), findsNothing);

    await chooseOption(tester, 'Mercado', 'Fijar');
    await waitFor(tester, find.text('FIJADAS'));
    expect(find.text('OTRAS'), findsOneWidget);

    await chooseOption(tester, 'Mercado', 'Dejar de fijar');
    await waitFor(tester, find.text('FIJADAS'), gone: true);
  });

  testWidgets('no deja fijar más de 5 listas', (tester) async {
    final repository = NoteRepositoryImpl();
    for (var i = 0; i < 6; i++) {
      await repository.addNote(newNote('$i', 'Lista $i'));
      if (i < 5) await repository.setPinned('$i', true);
    }
    await startApp(tester);
    await waitFor(tester, richText('Lista 5'));

    await chooseOption(tester, 'Lista 5', 'Fijar');
    await waitFor(tester, find.text('Solo puedes fijar hasta 5 listas'));
    expect((await repository.countPinnedNotes()).data, 5);
  });

  testWidgets('eliminar quita la lista y vuelve al vacío', (tester) async {
    await startApp(tester);
    await createList(tester, 'Mercado');
    await chooseOption(tester, 'Mercado', 'Eliminar');
    await waitFor(tester, find.text('Lista eliminada'));
    await waitFor(tester, find.text(emptyHome));

    await startApp(tester);
    expect(find.text(emptyHome), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpIntegrationTests();

  testWidgets('las listas sobreviven al reinicio', (tester) async {
    await startApp(tester);
    await createList(tester, 'Mercado', tasks: ['Pan']);
    await startApp(tester);
    expect(richText('Mercado'), findsOneWidget);

    await tapAndWait(tester, richText('Mercado'));
    await waitFor(tester, richText('Pan'));
  });

  testWidgets('una lista dañada muestra error y Reintentar funciona', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('${NoteRepositoryImpl.notePrefix}_1', '{no es json');

    await startApp(tester, home: find.text('Reintentar'));
    expect(find.text(emptyHome), findsNothing);

    await prefs.remove('${NoteRepositoryImpl.notePrefix}_1');
    await tapAndWait(tester, find.text('Reintentar'));
    await waitFor(tester, find.text(emptyHome));
  });
}

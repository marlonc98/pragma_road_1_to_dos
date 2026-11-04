import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpIntegrationTests();

  testWidgets('la app arranca sin listas', (tester) async {
    await startApp(tester);
    expect(find.text(emptyHome), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('crear una lista con título y dos tareas', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTitle(tester, 'Mercado');
    await typeTask(tester, 0, 'Pan');
    await addTask(tester);
    await typeTask(tester, 1, 'Leche');
    await save(tester);

    // Queda en vista previa, sin campos de texto
    await waitFor(tester, find.byTooltip('Editar'));
    expect(find.byType(TextFormField), findsNothing);
    expect(richText('Pan'), findsOneWidget);
    expect(richText('Leche'), findsOneWidget);

    await goBack(tester);
    await waitFor(tester, richText('Mercado'));
    expect(find.text(emptyHome), findsNothing);
  });

  testWidgets('crear varias listas seguidas', (tester) async {
    await startApp(tester);
    for (final title in ['Mercado', 'Trabajo', 'Viaje']) {
      await createList(tester, title);
    }
    for (final title in ['Mercado', 'Trabajo', 'Viaje']) {
      expect(richText(title), findsOneWidget);
    }
  });

  testWidgets('salir sin escribir no crea nada', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await goBack(tester);
    await waitFor(tester, find.text(emptyHome));
    expect(find.text(unsavedTitle), findsNothing);
  });

  testWidgets('un título de puros espacios no crea nada', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTitle(tester, '    ');
    await goBack(tester);
    await waitFor(tester, find.text(emptyHome));
  });
}

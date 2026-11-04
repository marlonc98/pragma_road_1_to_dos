import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpIntegrationTests();

  testWidgets('marcar una tarea la tacha y sobrevive al reinicio', (
    tester,
  ) async {
    await startApp(tester);
    await createList(tester, 'Mercado', tasks: ['Pan']);
    await tapAndWait(tester, richText('Mercado'));
    await waitFor(tester, find.byType(Checkbox));
    expect(taskIsCrossedOut(tester, 'Pan'), isFalse);

    await tapAndWait(tester, find.byType(Checkbox));
    expect(taskIsCrossedOut(tester, 'Pan'), isTrue);
    await waitFor(tester, find.text('Guardado'));

    await startApp(tester);
    await tapAndWait(tester, richText('Mercado'));
    await waitFor(tester, find.byType(Checkbox));
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    expect(taskIsCrossedOut(tester, 'Pan'), isTrue);
  });

  testWidgets('editar: agregar una tarea y borrar otra', (tester) async {
    await startApp(tester);
    await createList(tester, 'Mercado', tasks: ['Pan', 'Leche']);
    await tapAndWait(tester, richText('Mercado'));
    await tapAndWait(tester, find.byTooltip('Editar'));

    await tapAndWait(tester, find.byIcon(Icons.close).first);
    await addTask(tester);
    await typeTask(tester, 1, 'Huevos');
    await save(tester);
    await waitFor(tester, find.byTooltip('Editar'));

    expect(richText('Pan'), findsNothing);
    expect(richText('Leche'), findsOneWidget);
    expect(richText('Huevos'), findsOneWidget);
  });

  testWidgets('borrar el título al editar no deja guardar', (tester) async {
    await startApp(tester);
    await createList(tester, 'Mercado', tasks: ['Pan']);
    await tapAndWait(tester, richText('Mercado'));
    await tapAndWait(tester, find.byTooltip('Editar'));

    await typeTitle(tester, '');
    await save(tester);
    expect(find.text(requiredError), findsOneWidget);
    expect(find.byTooltip('Editar'), findsNothing);
  });
}

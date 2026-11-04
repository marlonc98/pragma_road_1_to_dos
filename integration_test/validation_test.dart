import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpIntegrationTests();

  testWidgets('guardar vacío marca el título y la tarea', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await save(tester);
    expect(find.text(requiredError), findsNWidgets(2));
    expect(find.byTooltip('Editar'), findsNothing);

    await goBack(tester);
    await waitFor(tester, find.text(emptyHome));
  });

  testWidgets('sin título no guarda hasta escribirlo', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTask(tester, 0, 'Pan');
    await save(tester);
    expect(find.text(requiredError), findsOneWidget);
    expect(find.byTooltip('Editar'), findsNothing);

    await typeTitle(tester, 'Mercado');
    await save(tester);
    await waitFor(tester, find.byTooltip('Editar'));
  });

  testWidgets('una tarea vacía no deja guardar, hasta borrarla', (
    tester,
  ) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTitle(tester, 'Mercado');
    await save(tester);
    expect(find.text(requiredError), findsOneWidget);

    await tapAndWait(tester, find.byIcon(Icons.close).first);
    await save(tester);
    await waitFor(tester, find.byTooltip('Editar'));
  });

  testWidgets('máximo 100 caracteres en título y tareas', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTitle(tester, 'a' * 101);
    await typeTask(tester, 0, 'b' * 101);
    await save(tester);
    expect(find.text(maxLengthError), findsNWidgets(2));

    await typeTitle(tester, 'a' * 100);
    await typeTask(tester, 0, 'b' * 100);
    await save(tester);
    await waitFor(tester, find.byTooltip('Editar'));
  });
}

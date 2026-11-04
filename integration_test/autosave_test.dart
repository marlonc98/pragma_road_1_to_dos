import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpIntegrationTests();

  testWidgets('salir con título guarda, sin la fila vacía', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTitle(tester, 'Mercado');
    await waitFor(tester, find.text('Guardado'));
    await goBack(tester);
    await waitFor(tester, richText('Mercado'));

    await tapAndWait(tester, richText('Mercado'));
    await waitFor(tester, find.byTooltip('Editar'));
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('sin título pregunta: Cancelar sigue editando', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTask(tester, 0, 'Pan');
    await goBack(tester);
    await waitFor(tester, find.text(unsavedTitle));

    await tapAndWait(tester, find.text('Cancelar'));
    expect(find.text(unsavedTitle), findsNothing);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('sin título pregunta: Descartar no crea nada', (tester) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTask(tester, 0, 'Pan');
    await goBack(tester);
    await waitFor(tester, find.text(unsavedTitle));

    await tapAndWait(tester, find.text('Descartar'));
    await waitFor(tester, find.text(emptyHome));
  });

  testWidgets('sin título pregunta: Guardar marca el error y se queda', (
    tester,
  ) async {
    await startApp(tester);
    await openNewList(tester);
    await typeTask(tester, 0, 'Pan');
    await goBack(tester);
    await waitFor(tester, find.text(unsavedTitle));

    await tapAndWait(
      tester,
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Guardar'),
      ),
    );
    await waitFor(tester, find.text(requiredError));
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}

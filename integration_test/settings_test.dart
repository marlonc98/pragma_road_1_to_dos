import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpIntegrationTests();

  testWidgets('sin autoguardado, salir pregunta y Descartar no guarda', (
    tester,
  ) async {
    await startApp(tester);
    await setSwitch(tester, 'Autoguardado');
    await openNewList(tester);
    await typeTitle(tester, 'Mercado');
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Guardado'), findsNothing);

    await goBack(tester);
    await waitFor(tester, find.text(unsavedTitle));
    await tapAndWait(tester, find.text('Descartar'));
    await waitFor(tester, find.text(emptyHome));
  });

  testWidgets('sin vista previa, las listas abren para editar', (tester) async {
    await startApp(tester);
    await createList(tester, 'Mercado');
    await setSwitch(tester, 'Tocar Editar para modificar');
    await tapAndWait(tester, richText('Mercado'));
    await waitFor(tester, find.byType(TextFormField));
    expect(find.byTooltip('Editar'), findsNothing);
  });

  testWidgets('los ajustes sobreviven al reinicio', (tester) async {
    await startApp(tester);
    await setSwitch(tester, 'Autoguardado');
    await startApp(tester);
    await tapAndWait(tester, find.byTooltip('Ajustes'));
    await waitFor(tester, find.byType(SwitchListTile));
    final tile = tester.widget<SwitchListTile>(
      find.widgetWithText(SwitchListTile, 'Autoguardado'),
    );
    expect(tile.value, isFalse);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_helpers.dart';

void main() {
  setUpIntegrationTests();

  testWidgets('encuentra, no encuentra y limpia', (tester) async {
    await startApp(tester);
    await createList(tester, 'Mercado', tasks: ['Pan']);
    await createList(tester, 'Trabajo', tasks: ['Informe']);
    final search = find.byType(TextField).first;

    // Por título
    await tester.enterText(search, 'merc');
    await waitFor(tester, richText('Trabajo'), gone: true);
    expect(richText('Mercado'), findsOneWidget);

    // Por tarea
    await tester.enterText(search, 'informe');
    await waitFor(tester, richText('Mercado'), gone: true);
    expect(richText('Trabajo'), findsOneWidget);

    // Sin resultados
    await tester.enterText(search, 'gimnasio');
    await waitFor(
      tester,
      find.text('No hay listas que coincidan con tu búsqueda'),
    );

    await tapAndWait(tester, find.text('Limpiar búsqueda'));
    await waitFor(tester, richText('Mercado'));
    expect(richText('Trabajo'), findsOneWidget);
  });

  testWidgets('buscar solo espacios o sin listas no rompe', (tester) async {
    await startApp(tester);
    await tester.enterText(find.byType(TextField).first, '   ');
    await tester.pump(const Duration(milliseconds: 700));
    expect(tester.takeException(), isNull);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}

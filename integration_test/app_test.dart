import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/flavors/flavors.dart';
import 'package:gestor_tareas_personales/presentation/app.dart';
import 'package:gestor_tareas_personales/presentation/pages/splash/splash_page.dart';
import 'package:gestor_tareas_personales/presentation/router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const emptyHome = 'Aún no tienes listas';
const requiredError = 'Este campo es obligatorio';
const maxLengthError = 'Debe tener máximo 100 caracteres';
const unsavedTitle = '¿Guardar los cambios?';

/// La app corre con los repositorios reales (SharedPreferences), pero se compila
/// con `--flavor mock` para no borrar los datos de la app dev o prod.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  F.appFlavor = Flavor.dev;

  setUp(() async {
    await (await SharedPreferences.getInstance()).clear();
  });

  group('crear listas', () {
    testWidgets('1. la app arranca sin listas', (tester) async {
      await startApp(tester);
      expect(find.text(emptyHome), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('2. crear una lista con título y dos tareas', (tester) async {
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

    testWidgets('3. crear varias listas seguidas', (tester) async {
      await startApp(tester);
      for (final title in ['Mercado', 'Trabajo', 'Viaje']) {
        await createList(tester, title);
      }
      for (final title in ['Mercado', 'Trabajo', 'Viaje']) {
        expect(richText(title), findsOneWidget);
      }
    });

    testWidgets('4. salir sin escribir no crea nada', (tester) async {
      await startApp(tester);
      await openNewList(tester);
      await goBack(tester);
      await waitFor(tester, find.text(emptyHome));
      expect(find.text(unsavedTitle), findsNothing);
    });

    testWidgets('5. un título de puros espacios no crea nada', (tester) async {
      await startApp(tester);
      await openNewList(tester);
      await typeTitle(tester, '    ');
      await goBack(tester);
      await waitFor(tester, find.text(emptyHome));
    });
  });

  group('validaciones', () {
    testWidgets('6. guardar vacío marca el título y la tarea', (tester) async {
      await startApp(tester);
      await openNewList(tester);
      await save(tester);
      expect(find.text(requiredError), findsNWidgets(2));
      expect(find.byTooltip('Editar'), findsNothing);

      await goBack(tester);
      await waitFor(tester, find.text(emptyHome));
    });

    testWidgets('7. sin título no guarda hasta escribirlo', (tester) async {
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

    testWidgets('8. una tarea vacía no deja guardar, hasta borrarla', (
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

    testWidgets('9. máximo 100 caracteres en título y tareas', (tester) async {
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
  });

  group('autoguardado y salir', () {
    testWidgets('10. salir con título guarda, sin la fila vacía', (
      tester,
    ) async {
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

    testWidgets('11. sin título pregunta: Cancelar sigue editando', (
      tester,
    ) async {
      await startApp(tester);
      await openNewList(tester);
      await typeTask(tester, 0, 'Pan');
      await goBack(tester);
      await waitFor(tester, find.text(unsavedTitle));

      await tapAndWait(tester, find.text('Cancelar'));
      expect(find.text(unsavedTitle), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    testWidgets('12. sin título pregunta: Descartar no crea nada', (
      tester,
    ) async {
      await startApp(tester);
      await openNewList(tester);
      await typeTask(tester, 0, 'Pan');
      await goBack(tester);
      await waitFor(tester, find.text(unsavedTitle));

      await tapAndWait(tester, find.text('Descartar'));
      await waitFor(tester, find.text(emptyHome));
    });

    testWidgets('13. sin título pregunta: Guardar marca el error y se queda', (
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
  });

  group('vista previa y edición', () {
    testWidgets('14. marcar una tarea la tacha y sobrevive al reinicio', (
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

    testWidgets('15. editar: agregar una tarea y borrar otra', (tester) async {
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

    testWidgets('16. borrar el título al editar no deja guardar', (
      tester,
    ) async {
      await startApp(tester);
      await createList(tester, 'Mercado', tasks: ['Pan']);
      await tapAndWait(tester, richText('Mercado'));
      await tapAndWait(tester, find.byTooltip('Editar'));

      await typeTitle(tester, '');
      await save(tester);
      expect(find.text(requiredError), findsOneWidget);
      expect(find.byTooltip('Editar'), findsNothing);
    });
  });

  group('búsqueda', () {
    testWidgets('17. encuentra, no encuentra y limpia', (tester) async {
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

    testWidgets('18. buscar solo espacios o sin listas no rompe', (
      tester,
    ) async {
      await startApp(tester);
      await tester.enterText(find.byType(TextField).first, '   ');
      await tester.pump(const Duration(milliseconds: 700));
      expect(tester.takeException(), isNull);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  group('opciones de la lista', () {
    testWidgets('19. fijar y dejar de fijar', (tester) async {
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

    testWidgets('20. no deja fijar más de 5 listas', (tester) async {
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

    testWidgets('21. eliminar quita la lista y vuelve al vacío', (
      tester,
    ) async {
      await startApp(tester);
      await createList(tester, 'Mercado');
      await chooseOption(tester, 'Mercado', 'Eliminar');
      await waitFor(tester, find.text('Lista eliminada'));
      await waitFor(tester, find.text(emptyHome));

      await startApp(tester);
      expect(find.text(emptyHome), findsOneWidget);
    });
  });

  group('ajustes', () {
    testWidgets('22. sin autoguardado, salir pregunta y Descartar no guarda', (
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

    testWidgets('23. sin vista previa, las listas abren para editar', (
      tester,
    ) async {
      await startApp(tester);
      await createList(tester, 'Mercado');
      await setSwitch(tester, 'Tocar Editar para modificar');
      await tapAndWait(tester, richText('Mercado'));
      await waitFor(tester, find.byType(TextFormField));
      expect(find.byTooltip('Editar'), findsNothing);
    });

    testWidgets('24. los ajustes sobreviven al reinicio', (tester) async {
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
  });

  group('persistencia y errores', () {
    testWidgets('25. las listas sobreviven al reinicio', (tester) async {
      await startApp(tester);
      await createList(tester, 'Mercado', tasks: ['Pan']);
      await startApp(tester);
      expect(richText('Mercado'), findsOneWidget);

      await tapAndWait(tester, richText('Mercado'));
      await waitFor(tester, richText('Pan'));
    });

    testWidgets('26. una lista dañada muestra error y Reintentar funciona', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${NoteRepositoryImpl.notePrefix}_1',
        '{no es json',
      );

      await startApp(tester, home: find.text('Reintentar'));
      expect(find.text(emptyHome), findsNothing);

      await prefs.remove('${NoteRepositoryImpl.notePrefix}_1');
      await tapAndWait(tester, find.text('Reintentar'));
      await waitFor(tester, find.text(emptyHome));
    });
  });
}

// ---- Helpers ----

Finder richText(String text) => find.text(text, findRichText: true);

NoteEntity newNote(String id, String title) => NoteEntity(
  id: id,
  title: title,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Como `pumpAndSettle`, pero sirve con el spinner y los timers reales.
Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  bool gone = false,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty != gone) {
    if (DateTime.now().isAfter(end)) {
      throw TestFailure(
        '${gone ? 'Sigue en pantalla' : 'No apareció'}: ${finder.describeMatch(Plurality.zero)}',
      );
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pump(const Duration(milliseconds: 100));
}

/// Abre la app desde cero, como al reiniciarla, y espera el home.
Future<void> startApp(WidgetTester tester, {Finder? home}) async {
  if (!tester.testTextInput.isRegistered) {
    tester.testTextInput.register();
    addTearDown(tester.testTextInput.unregister);
  }
  await tester.pumpWidget(const SizedBox());
  router.go(SplashPage.route);
  await tester.pumpWidget(ProviderScope(key: UniqueKey(), child: const App()));
  await waitFor(tester, find.byType(FloatingActionButton));
  await waitFor(
    tester,
    home ?? find.byType(CircularProgressIndicator),
    gone: home == null,
  );
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
  await waitFor(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> openNewList(WidgetTester tester) async {
  await tapAndWait(tester, find.byType(FloatingActionButton));
  await waitFor(tester, find.byType(TextFormField));
}

Future<void> typeTitle(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextFormField).first, text);
  await tester.pump();
}

/// Espera el debounce de la fila antes de seguir.
Future<void> typeTask(WidgetTester tester, int index, String text) async {
  await tester.enterText(find.byType(TextFormField).at(index + 1), text);
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> addTask(WidgetTester tester) =>
    tapAndWait(tester, find.text('Agregar tarea'));

Future<void> save(WidgetTester tester) =>
    tapAndWait(tester, find.widgetWithText(TextButton, 'Guardar'));

Future<void> goBack(WidgetTester tester) =>
    tapAndWait(tester, find.byType(BackButton));

/// Crea una lista completa desde el home y vuelve al home.
Future<void> createList(
  WidgetTester tester,
  String title, {
  List<String> tasks = const [],
}) async {
  await openNewList(tester);
  await typeTitle(tester, title);
  for (final (index, task) in tasks.indexed) {
    if (index > 0) await addTask(tester);
    await typeTask(tester, index, task);
  }
  if (tasks.isEmpty) await tapAndWait(tester, find.byIcon(Icons.close).first);
  await save(tester);
  await waitFor(tester, find.byTooltip('Editar'));
  await goBack(tester);
  await waitFor(tester, find.byType(FloatingActionButton));
  await waitFor(tester, richText(title));
}

Future<void> chooseOption(
  WidgetTester tester,
  String list,
  String option,
) async {
  await waitFor(tester, richText(list));
  await tester.longPress(richText(list));
  await tester.pump(const Duration(milliseconds: 500));
  await tapAndWait(tester, find.text(option));
}

/// Cambia un ajuste y vuelve al home.
Future<void> setSwitch(WidgetTester tester, String title) async {
  await tapAndWait(tester, find.byTooltip('Ajustes'));
  await tapAndWait(tester, find.widgetWithText(SwitchListTile, title));
  await tester.pump(const Duration(milliseconds: 300));
  await goBack(tester);
  await waitFor(tester, find.byType(FloatingActionButton));
}

bool taskIsCrossedOut(WidgetTester tester, String task) {
  final text = tester.widget<Text>(
    find.byWidgetPredicate(
      (widget) => widget is Text && widget.textSpan?.toPlainText() == task,
    ),
  );
  return text.style?.decoration == TextDecoration.lineThrough;
}

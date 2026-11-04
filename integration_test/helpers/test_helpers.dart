import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
void setUpIntegrationTests() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  F.appFlavor = Flavor.dev;

  setUp(() async {
    await (await SharedPreferences.getInstance()).clear();
  });
}

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

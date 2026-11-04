import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late NoteRepositoryImpl repository;
  late ProviderContainer container;

  final addIcon = find.byIcon(Icons.add);
  final deleteIcon = find.byIcon(Icons.close);
  final editIcon = find.byIcon(Icons.edit_outlined);
  final saveIcon = find.byIcon(Icons.check);
  // En los tests no hay traducciones cargadas: se muestra la clave
  const requiredError = TextConstants.validatorRequired;
  const lengthError = TextConstants.validatorMaxLength;

  NoteEntity sampleNote() => NoteEntity(
    id: '1',
    title: 'Mercado',
    content: [
      TaskEntity(id: 'a', content: 'Pan', completed: true),
      TaskEntity(id: 'b', content: 'Leche'),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = NoteRepositoryImpl();
    container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpEditor(
    WidgetTester tester, {
    NoteEntity? note,
    SettingsEntity settings = const SettingsEntity(),
  }) async {
    container.read(settingsStateProvider.notifier).setSettings(settings);
    if (note != null) await tester.runAsync(() => repository.addNote(note));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: NoteEditorPage(note: note)),
      ),
    );
    await tester.pumpAndSettle();
  }

  // El temporizador del autoguardado corre con el reloj falso del test, y el
  // guardado en shared_preferences con el real.
  Future<void> settleSave(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  Future<void> waitForAutosave(WidgetTester tester) async {
    await tester.pump(NoteEditorPageViewModel.autosaveDelay);
    await settleSave(tester);
  }

  Future<List<NoteEntity>> savedNotes(WidgetTester tester) async =>
      (await tester.runAsync(() => repository.getNotes()))!.data!;

  TextField taskField(WidgetTester tester, int index) =>
      tester.widget(find.byType(TextField).at(index + 1));

  group('lista nueva', () {
    testWidgets('abre editando, sin importar los ajustes', (tester) async {
      await pumpEditor(tester);
      expect(find.byType(TextField), findsNWidgets(2));
      expect(addIcon, findsOneWidget);
      expect(editIcon, findsNothing);
      expect(saveIcon, findsOneWidget);
    });

    testWidgets('al marcar una tarea se tacha y se autoguarda', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Mercado');
      await tester.enterText(find.byType(TextField).at(1), 'Comprar pan');
      await tester.pump(const Duration(milliseconds: 500));
      expect(
        taskField(tester, 0).style?.decoration,
        isNot(TextDecoration.lineThrough),
      );

      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(
        taskField(tester, 0).style?.decoration,
        TextDecoration.lineThrough,
      );

      await waitForAutosave(tester);
      final saved = (await savedNotes(tester)).single;
      expect(saved.content.single.content, 'Comprar pan');
      expect(saved.content.single.completed, isTrue);
    });

    testWidgets('al escribir, espera a que termine para autoguardar', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Mercado');
      await waitForAutosave(tester);
      await tester.enterText(find.byType(TextField).at(1), 'Comprar');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(TextField).at(1), 'Comprar pan');

      // La espera de la fila volvió a empezar y aún falta la del autoguardado
      await tester.pump(NoteEditorPageViewModel.autosaveDelay);
      await settleSave(tester);
      expect((await savedNotes(tester)).single.content, isEmpty);

      await tester.pump(const Duration(milliseconds: 500));
      await settleSave(tester);
      final saved = (await savedNotes(tester)).single;
      expect(saved.content.single.content, 'Comprar pan');
    });

    testWidgets('Guardar justo después de escribir no pierde el texto', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Mercado');
      await tester.enterText(find.byType(TextField).at(1), 'Comprar pan');
      await tester.tap(saveIcon);
      await settleSave(tester);
      final saved = (await savedNotes(tester)).single;
      expect(saved.content.single.content, 'Comprar pan');
    });

    testWidgets('la barra de formato no toca el título desde una tarea', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Mercado');
      await tester.enterText(find.byType(TextField).at(1), 'Pan');
      await tester.tap(find.byIcon(Icons.format_bold));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField).at(0)).controller?.text,
        'Mercado',
      );
    });

    testWidgets('Enter crea otra tarea debajo, pero no desde una vacía', (
      tester,
    ) async {
      await pumpEditor(tester);
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.showKeyboard(find.byType(TextField).at(1));
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), 'Primera');
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();
      await tester.pump();
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(taskField(tester, 1).focusNode?.hasFocus, isTrue);
    });

    testWidgets('Guardar sin nada marca los errores y sigue editando', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.tap(saveIcon);
      await tester.pump();
      expect(find.text(requiredError), findsNWidgets(2));
      expect(find.byType(TextField), findsNWidgets(2));
      expect(await savedNotes(tester), isEmpty);
    });

    testWidgets('Guardar sin título no guarda, aunque haya tareas', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(1), 'Pan');
      await tester.pump();
      await tester.tap(saveIcon);
      await settleSave(tester);
      expect(find.text(requiredError), findsOneWidget);
      expect(taskField(tester, -1).focusNode?.hasFocus, isTrue);
      expect(await savedNotes(tester), isEmpty);
    });

    testWidgets('Guardar con una tarea vacía no guarda y le da el foco', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Mercado');
      await tester.pump();
      await tester.tap(saveIcon);
      await settleSave(tester);
      expect(find.text(requiredError), findsOneWidget);
      expect(taskField(tester, 0).focusNode?.hasFocus, isTrue);
      expect(await savedNotes(tester), isEmpty);
    });

    testWidgets('una tarea con error pone el check en rojo hasta corregirla', (
      tester,
    ) async {
      await pumpEditor(tester);
      Checkbox checkbox() => tester.widget<Checkbox>(find.byType(Checkbox));
      expect(checkbox().isError, isFalse);

      await tester.tap(saveIcon);
      await tester.pump();
      await tester.pump();
      expect(checkbox().isError, isTrue);

      await tester.enterText(find.byType(TextField).at(1), 'Pan');
      await tester.pump();
      await tester.pump();
      expect(checkbox().isError, isFalse);
    });

    testWidgets('título y tareas admiten hasta 100 caracteres', (tester) async {
      await pumpEditor(tester);
      const limit = NoteEditorPageViewModel.maxTextLength;
      await tester.enterText(find.byType(TextField).at(0), 'a' * limit);
      await tester.enterText(find.byType(TextField).at(1), 'b' * limit);
      await tester.pump();
      expect(find.text(lengthError), findsNothing);

      await tester.enterText(find.byType(TextField).at(0), 'a' * (limit + 1));
      await tester.enterText(find.byType(TextField).at(1), 'b' * (limit + 1));
      await tester.pump();
      expect(find.text(lengthError), findsNWidgets(2));

      await tester.tap(saveIcon);
      await settleSave(tester);
      expect(await savedNotes(tester), isEmpty);
    });

    testWidgets('el autoguardado no guarda textos de más de 100 caracteres', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Mercado');
      await tester.enterText(find.byType(TextField).at(1), 'b' * 101);
      await tester.pump(const Duration(milliseconds: 500));
      await waitForAutosave(tester);
      expect(await savedNotes(tester), isEmpty);
    });

    testWidgets('el error sale al vaciar un campo, no al abrir ni al agregar', (
      tester,
    ) async {
      await pumpEditor(tester);
      expect(find.text(requiredError), findsNothing);
      await tester.enterText(find.byType(TextField).at(1), 'Pan');
      await tester.pump();
      await tester.tap(addIcon);
      await tester.pump();
      await tester.pump();
      expect(find.text(requiredError), findsNothing);

      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.pump();
      expect(find.text(requiredError), findsOneWidget);
    });

    testWidgets('el autoguardado espera al título y no guarda filas vacías', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(find.byType(TextField).at(1), 'Pan');
      await tester.pump(const Duration(milliseconds: 500));
      await waitForAutosave(tester);
      expect(await savedNotes(tester), isEmpty);

      await tester.tap(addIcon);
      await tester.pump();
      await tester.pump();
      await tester.enterText(find.byType(TextField).at(0), 'Mercado');
      await waitForAutosave(tester);
      final saved = (await savedNotes(tester)).single;
      expect(saved.title, 'Mercado');
      expect(saved.content.map((task) => task.content), ['Pan']);
    });
  });

  testWidgets('la barra de formato solo tiene negrita y cursiva', (
    tester,
  ) async {
    await pumpEditor(tester);
    expect(find.byIcon(Icons.format_bold), findsOneWidget);
    expect(find.byIcon(Icons.format_italic), findsOneWidget);
    expect(find.byIcon(Icons.format_strikethrough), findsNothing);
    expect(find.byIcon(Icons.format_list_bulleted), findsNothing);
  });

  group('tocar Editar para modificar (por defecto)', () {
    testWidgets('abre en vista previa, sin agregar, eliminar ni barra', (
      tester,
    ) async {
      await pumpEditor(tester, note: sampleNote());
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('Pan'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.byType(TextField), findsNothing);
      expect(addIcon, findsNothing);
      expect(deleteIcon, findsNothing);
      expect(find.byIcon(Icons.format_bold), findsNothing);
      expect(saveIcon, findsNothing);
      expect(editIcon, findsOneWidget);
    });

    testWidgets('en vista previa, marcar tacha y guarda de una', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        note: sampleNote(),
        settings: const SettingsEntity(autoSave: false),
      );
      final style = tester.widget<Text>(find.textContaining('Leche')).style;
      expect(style?.decoration, isNot(TextDecoration.lineThrough));

      await tester.tap(find.byType(Checkbox).last);
      await settleSave(tester);
      expect(
        tester.widget<Text>(find.textContaining('Leche')).style?.decoration,
        TextDecoration.lineThrough,
      );
      final saved = (await savedNotes(tester)).single;
      expect(saved.content.last.completed, isTrue);
    });

    testWidgets('Editar muestra los controles y Guardar vuelve a la vista', (
      tester,
    ) async {
      await pumpEditor(tester, note: sampleNote());
      await tester.tap(editIcon);
      await tester.pump();
      expect(find.byType(TextField), findsNWidgets(3));
      expect(addIcon, findsOneWidget);
      expect(deleteIcon, findsNWidgets(2));
      expect(find.byIcon(Icons.format_bold), findsOneWidget);
      expect(saveIcon, findsOneWidget);

      await tester.tap(deleteIcon.first);
      await tester.pump();
      await tester.tap(addIcon);
      await tester.pump();
      await tester.pump();
      await tester.tap(saveIcon);
      await settleSave(tester);
      await tester.pump();

      // La fila nueva quedó vacía: no deja guardar hasta quitarla
      expect(find.text(requiredError), findsOneWidget);
      expect(saveIcon, findsOneWidget);
      await tester.tap(deleteIcon.last);
      await tester.pump();
      await tester.tap(saveIcon);
      await settleSave(tester);
      await tester.pump();

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Checkbox), findsOneWidget);
      expect(find.text('Pan'), findsNothing);
      expect(editIcon, findsOneWidget);
      final saved = (await savedNotes(tester)).single;
      expect(saved.content.map((task) => task.content), ['Leche']);
      final inState = container.read(notesStateProvider).data!;
      expect(inState.single.content.map((task) => task.content), ['Leche']);
    });
  });

  testWidgets(
    'en vista previa, marcar guarda aunque la lista no tenga título',
    (tester) async {
      final note = NoteEntity(
        id: '1',
        content: [TaskEntity(id: 'a', content: 'Pan')],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
      await pumpEditor(tester, note: note);
      await tester.tap(find.byType(Checkbox));
      await settleSave(tester);
      final saved = (await savedNotes(tester)).single;
      expect(saved.content.single.completed, isTrue);
    },
  );

  group('sin tocar Editar', () {
    testWidgets('con autoguardado abre editando y sin botón de guardar', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        note: sampleNote(),
        settings: const SettingsEntity(requireEditMode: false),
      );
      expect(find.byType(TextField), findsNWidgets(3));
      expect(editIcon, findsNothing);
      expect(saveIcon, findsNothing);

      await tester.tap(deleteIcon.first);
      await tester.pump();
      await waitForAutosave(tester);
      final saved = (await savedNotes(tester)).single;
      expect(saved.content.map((task) => task.content), ['Leche']);
    });

    testWidgets('sin autoguardado, Guardar guarda y sigue editando', (
      tester,
    ) async {
      await pumpEditor(
        tester,
        note: sampleNote(),
        settings: const SettingsEntity(autoSave: false, requireEditMode: false),
      );
      await tester.tap(deleteIcon.first);
      await tester.pump();
      await waitForAutosave(tester);
      expect((await savedNotes(tester)).single.content, hasLength(2));

      await tester.tap(saveIcon);
      await settleSave(tester);
      expect((await savedNotes(tester)).single.content, hasLength(1));
      expect(find.byType(TextField), findsNWidgets(2));
      expect(saveIcon, findsOneWidget);
    });
  });

  group('salir con autoguardado', () {
    Future<void> openNew(WidgetTester tester, {NoteEntity? note}) async {
      final router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: '/editor',
            builder: (_, state) =>
                NoteEditorPage(note: state.extra as NoteEntity?),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.push('/editor', extra: note);
      await tester.pumpAndSettle();
    }

    Future<void> exit(WidgetTester tester) async {
      await tester.tap(find.byType(BackButton));
      await tester.pump();
      await settleSave(tester);
      await tester.pumpAndSettle();
    }

    testWidgets('sin nada escrito sale sin preguntar ni guardar', (
      tester,
    ) async {
      await openNew(tester);
      await exit(tester);
      expect(find.byType(NoteEditorPage), findsNothing);
      expect(await savedNotes(tester), isEmpty);
    });

    testWidgets('con título guarda y deja fuera las filas vacías', (
      tester,
    ) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField).at(0), 'Mercado');
      await exit(tester);
      expect(find.byType(NoteEditorPage), findsNothing);
      final saved = (await savedNotes(tester)).single;
      expect(saved.title, 'Mercado');
      expect(saved.content, isEmpty);
    });

    testWidgets('sin título pregunta: Guardar marca el error y se queda', (
      tester,
    ) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField).at(1), 'Pan');
      await exit(tester);
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextButton),
            )
            .at(2),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditorPage), findsOneWidget);
      expect(find.text(requiredError), findsOneWidget);
      expect(await savedNotes(tester), isEmpty);
    });

    testWidgets('sin título, Descartar sale sin guardar', (tester) async {
      await openNew(tester);
      await tester.enterText(find.byType(TextField).at(1), 'Pan');
      await exit(tester);
      await tester.tap(
        find
            .descendant(
              of: find.byType(AlertDialog),
              matching: find.byType(TextButton),
            )
            .at(1),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditorPage), findsNothing);
      expect(await savedNotes(tester), isEmpty);
    });
  });

  group('salir sin autoguardado', () {
    late GoRouter router;

    Future<void> openWithChanges(WidgetTester tester) async {
      container
          .read(settingsStateProvider.notifier)
          .setSettings(const SettingsEntity(autoSave: false));
      final note = sampleNote();
      await tester.runAsync(() => repository.addNote(note));
      router = GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: '/editor',
            builder: (_, state) =>
                NoteEditorPage(note: state.extra as NoteEntity?),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      router.push('/editor', extra: note);
      await tester.pumpAndSettle();
      await tester.tap(editIcon);
      await tester.pump();
      await tester.tap(deleteIcon.first);
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
    }

    Finder dialogButton(int index) => find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextButton),
        )
        .at(index);

    testWidgets('Cancelar se queda editando', (tester) async {
      await openWithChanges(tester);
      await tester.tap(dialogButton(0));
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditorPage), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('Descartar sale sin guardar', (tester) async {
      await openWithChanges(tester);
      await tester.tap(dialogButton(1));
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditorPage), findsNothing);
      expect((await savedNotes(tester)).single.content, hasLength(2));
    });

    testWidgets('Guardar guarda y sale', (tester) async {
      await openWithChanges(tester);
      await tester.tap(dialogButton(2));
      await tester.pump();
      await settleSave(tester);
      await tester.pumpAndSettle();
      expect(find.byType(NoteEditorPage), findsNothing);
      expect((await savedNotes(tester)).single.content, hasLength(1));
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/notes_grid_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/error_loading_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/loading_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

NoteEntity note(
  String id,
  String title, {
  bool pinned = false,
  List<TaskEntity> content = const [],
}) => NoteEntity(
  id: id,
  title: title,
  pinned: pinned,
  content: content,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

class _HeldRepository extends NoteRepositoryImpl {
  final Completer<AsyncState<List<NoteEntity>>> completer = Completer();
  int calls = 0;

  @override
  Future<AsyncState<List<NoteEntity>>> getNotes() {
    calls++;
    return completer.future;
  }
}

void main() {
  late NoteRepositoryImpl repository;
  late ProviderContainer container;

  ProviderContainer createContainer(NoteRepositoryImpl repository) {
    final container = ProviderContainer(
      overrides: [noteRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = NoteRepositoryImpl();
    container = createContainer(repository);
  });

  Future<void> pumpPageOnly(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: NotesPage()),
      ),
    );
    await tester.pump();
  }

  // La lectura corre con el reloj real
  Future<void> finishLoading(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    List<NoteEntity> notes = const [],
  }) async {
    await tester.runAsync(() async {
      for (final note in notes) {
        await repository.addNote(note);
        if (note.pinned) await repository.setPinned(note.id, true);
      }
    });
    await pumpPageOnly(tester);
    await finishLoading(tester);
  }

  testWidgets('al abrir carga las notas: ruedita y luego las secciones', (
    tester,
  ) async {
    final held = _HeldRepository();
    container = createContainer(held);
    await pumpPageOnly(tester);
    expect(held.calls, 1);
    expect(find.byType(LoadingWidget), findsOneWidget);

    held.completer.complete(
      AsyncState.success(
        data: [note('1', 'Fijada', pinned: true), note('2', 'Normal')],
      ),
    );
    await finishLoading(tester);
    expect(find.byType(LoadingWidget), findsNothing);
    expect(
      find.descendant(
        of: find.byType(NotesGridWidget),
        matching: find.text('Fijada'),
      ),
      findsOneWidget,
    );
    expect(find.text('Normal'), findsOneWidget);
  });

  testWidgets('se actualiza sola cuando un caso de uso cambia el estado', (
    tester,
  ) async {
    await pumpPage(tester, notes: [note('1', 'Original')]);
    expect(find.text('Original'), findsOneWidget);

    await tester.runAsync(
      () => container
          .read(saveNoteUseCaseProvider)
          .updateNote(note('1', 'Editada')),
    );
    await tester.pump();
    expect(find.text('Original'), findsNothing);
    expect(find.text('Editada'), findsOneWidget);
    expect(find.byType(LoadingWidget), findsNothing);
  });

  testWidgets('la búsqueda filtra en memoria por título y tareas', (
    tester,
  ) async {
    await pumpPage(
      tester,
      notes: [
        note('1', 'Mercado'),
        note(
          '2',
          'Trabajo',
          content: [TaskEntity(id: 'a', content: 'Llamar')],
        ),
      ],
    );

    await tester.enterText(find.byType(TextField), 'merc');
    await tester.pump();
    expect(find.text('Mercado'), findsOneWidget);
    expect(find.text('Trabajo'), findsNothing);

    await tester.enterText(find.byType(TextField), 'llam');
    await tester.pump();
    expect(find.text('Mercado'), findsNothing);
    expect(find.text('Trabajo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'nada');
    await tester.pump();
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('muestra el error con reintentar', (tester) async {
    final held = _HeldRepository();
    container = createContainer(held);
    await pumpPageOnly(tester);
    held.completer.complete(AsyncState.fromError('noteNotFound'));
    await finishLoading(tester);
    expect(find.byType(LoadingWidget), findsNothing);
    expect(find.byType(ErrorLoadingWidget), findsOneWidget);
  });

  testWidgets('la tarjeta muestra hasta 10 tareas y avisa si hay más', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 4000);
    addTearDown(tester.view.resetPhysicalSize);
    await pumpPage(
      tester,
      notes: [
        note(
          '1',
          'Larga',
          content: List.generate(
            12,
            (i) => TaskEntity(id: '$i', content: 'tarea $i'),
          ),
        ),
      ],
    );
    expect(find.byIcon(Icons.check_box_outline_blank), findsNWidgets(10));
    expect(find.text('...'), findsOneWidget);
  });
}

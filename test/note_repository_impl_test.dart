import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

NoteEntity note(
  String id, {
  String? title,
  List<TaskEntity> content = const [],
  int day = 1,
}) => NoteEntity(
  id: id,
  title: title,
  content: content,
  createdAt: DateTime(2026, 1, day),
  updatedAt: DateTime(2026, 1, day),
);

void main() {
  late NoteRepositoryImpl repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = NoteRepositoryImpl();
  });

  Future<List<NoteEntity>> allNotes() async =>
      (await repository.getNotes()).data!;

  test('guarda cada nota en {prefijo}_{id}', () async {
    await repository.addNote(note('1', title: 'Hola'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), contains('sp_note_1'));
  });

  test('devuelve todas, de la más reciente a la más vieja', () async {
    await repository.addNote(note('1', title: 'Mercado', day: 1));
    await repository.addNote(note('2', title: 'Gimnasio', day: 2));
    expect((await allNotes()).map((note) => note.id), ['2', '1']);
  });

  test('guarda las tareas completas y con su estado', () async {
    final content = [
      TaskEntity(id: 'a', content: 'Comprar pan', completed: true),
      for (var i = 0; i < 11; i++) TaskEntity(id: '$i', content: 'tarea $i'),
    ];
    await repository.addNote(note('1', content: content));

    final tasks = (await allNotes()).single.content;
    expect(tasks, hasLength(12));
    expect(tasks.first.id, 'a');
    expect(tasks.first.content, 'Comprar pan');
    expect(tasks.first.completed, isTrue);
    expect(tasks.last.content, 'tarea 10');
    expect(tasks.last.completed, isFalse);
  });

  test('las notas viejas con texto se leen como tareas', () async {
    SharedPreferences.setMockInitialValues({
      'sp_note_1': jsonEncode({
        'id': '1',
        'title': 'Vieja',
        'content': '- uno\n\n~~dos~~\ntres ~~cuatro~~ **cinco**',
        'createdAt': DateTime(2026).toIso8601String(),
        'updatedAt': DateTime(2026).toIso8601String(),
      }),
    });

    final tasks = (await allNotes()).single.content;
    expect(tasks.map((task) => task.content), [
      'uno',
      'dos',
      'tres cuatro **cinco**',
    ]);
    expect(tasks.map((task) => task.completed), [false, true, false]);
    expect(tasks.map((task) => task.id).toSet(), hasLength(3));
  });

  test('las fijadas guardan solo el id y se marcan al cargar', () async {
    await repository.addNote(note('1', title: 'Hola'));
    await repository.addNote(note('2', title: 'Otra'));
    await repository.setPinned('1', true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('sp_pinned_notes'), ['1']);
    expect(prefs.getString('sp_note_1'), isNot(contains('pinned')));
    final notes = await allNotes();
    expect(notes.singleWhere((note) => note.id == '1').pinned, isTrue);
    expect(notes.singleWhere((note) => note.id == '2').pinned, isFalse);
    expect((await repository.countPinnedNotes()).data, 1);

    await repository.setPinned('1', false);
    expect((await repository.countPinnedNotes()).data, 0);
  });

  test('al borrar quita la nota y su id de las fijadas', () async {
    await repository.addNote(note('1', title: 'Hola'));
    await repository.setPinned('1', true);
    await repository.deleteNote('1');

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isNot(contains('sp_note_1')));
    expect(prefs.getStringList('sp_pinned_notes'), isEmpty);
  });
}

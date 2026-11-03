import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/repositories/note/note_repository_impl.dart';
import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

NoteEntity note(String id, {String? title, String? content, int day = 1}) =>
    NoteEntity(
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

  test('guarda cada nota en {prefijo}_{id}', () async {
    await repository.addNote(note('1', title: 'Hola'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), contains('sp_note_1'));
  });

  test('lista de la más reciente a la más vieja y filtra por texto', () async {
    await repository.addNote(note('1', title: 'Mercado', day: 1));
    await repository.addNote(note('2', title: 'Gimnasio', day: 2));

    final all = await repository.getNotes(page: 1, itemsPerPage: 20);
    expect(all.data!.data.map((note) => note.id), ['2', '1']);

    final filtered = await repository.getNotes(
      page: 1,
      itemsPerPage: 20,
      query: 'merc',
    );
    expect(filtered.data!.data.map((note) => note.id), ['1']);
  });

  test('recorta a 10 renglones al listar, pero no al abrir por id', () async {
    final content = List.generate(12, (i) => 'renglón $i').join('\n');
    await repository.addNote(note('1', content: content));

    final listed = (await repository.getNotes(
      page: 1,
      itemsPerPage: 20,
    )).data!.data.single;
    expect(listed.content!.split('\n'), hasLength(10));
    expect(listed.content, endsWith('renglón 9...'));

    final full = await repository.getNoteById('1');
    expect(full.data!.content, content);
  });

  test('una nota que no existe da noteNotFound', () async {
    final response = await repository.getNoteById('nope');
    expect(response.error, ErrorsConstants.noteNotFound);
  });

  test('las fijadas guardan solo el id y se marcan al cargar', () async {
    await repository.addNote(note('1', title: 'Hola'));
    await repository.setPinned('1', true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getStringList('sp_pinned_notes'), ['1']);
    expect(prefs.getString('sp_note_1'), isNot(contains('pinned')));
    expect((await repository.getNoteById('1')).data!.pinned, isTrue);
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

  test('las fijadas salen solo en getPinnedNotes', () async {
    await repository.addNote(note('1', title: 'Fijada', day: 1));
    await repository.addNote(note('2', title: 'Normal', day: 2));
    await repository.setPinned('1', true);

    final pinned = await repository.getPinnedNotes();
    expect(pinned.data!.map((note) => note.id), ['1']);
    expect(pinned.data!.single.pinned, isTrue);

    final others = await repository.getNotes(page: 1, itemsPerPage: 20);
    expect(others.data!.data.map((note) => note.id), ['2']);
  });

  test('pagina las notas no fijadas', () async {
    for (var day = 1; day <= 5; day++) {
      await repository.addNote(note('$day', title: 'Nota $day', day: day));
    }
    final first = await repository.getNotes(page: 1, itemsPerPage: 2);
    expect(first.data!.data.map((note) => note.id), ['5', '4']);
    expect(first.data!.totalItems, 5);
    expect(first.data!.lastpage, 3);

    final last = await repository.getNotes(page: 3, itemsPerPage: 2);
    expect(last.data!.data.map((note) => note.id), ['1']);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';

NoteEntity note({String? title, List<String> tasks = const []}) => NoteEntity(
  id: '1',
  title: title,
  content: [
    for (final (index, task) in tasks.indexed)
      TaskEntity(id: '$index', content: task),
  ],
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

void main() {
  group('vacíos', () {
    test('sin título ni tareas está vacía', () {
      expect(note().isEmpty, isTrue);
      expect(note().hasTitle, isFalse);
      expect(note().hasContent, isFalse);
    });

    test('un título vacío o de espacios no cuenta', () {
      expect(note(title: '').hasTitle, isFalse);
      expect(note(title: '   ').hasTitle, isFalse);
      expect(note(title: '   ').isEmpty, isTrue);
    });

    test('tareas vacías o de espacios no cuentan', () {
      expect(note(tasks: ['', '   ']).hasContent, isFalse);
      expect(note(tasks: ['', '   ']).isEmpty, isTrue);
    });

    test('con solo título o solo una tarea con texto no está vacía', () {
      expect(note(title: 'Mercado').isEmpty, isFalse);
      expect(note(tasks: ['', 'Pan']).isEmpty, isFalse);
    });
  });

  group('búsqueda', () {
    final mercado = note(title: 'Mercado', tasks: ['Comprar Pan']);

    test('una búsqueda vacía coincide con todo, incluso sin título', () {
      expect(mercado.matches(''), isTrue);
      expect(note().matches(''), isTrue);
    });

    test('busca en título y tareas, sin importar mayúsculas', () {
      expect(mercado.matches('MERC'), isTrue);
      expect(mercado.matches('pan'), isTrue);
    });

    test('sin coincidencias, o sin título ni tareas, no coincide', () {
      expect(mercado.matches('gimnasio'), isFalse);
      expect(note().matches('algo'), isFalse);
    });
  });

  test('copyWith solo cambia lo indicado, y nunca id ni createdAt', () {
    final original = note(title: 'Mercado', tasks: ['Pan']);
    final copy = original.copyWith(pinned: true, updatedAt: DateTime(2027));
    expect(copy.id, original.id);
    expect(copy.createdAt, original.createdAt);
    expect(copy.title, 'Mercado');
    expect(copy.content, original.content);
    expect(copy.pinned, isTrue);
    expect(copy.updatedAt, DateTime(2027));
  });
}

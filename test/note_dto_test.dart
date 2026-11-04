import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_tareas_personales/data/dto/note_dto.dart';
import 'package:gestor_tareas_personales/data/dto/task_dto.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';

void main() {
  final entity = NoteEntity(
    id: '1',
    title: 'Mercado',
    content: [TaskEntity(id: 'a', content: 'Pan', completed: true)],
    pinned: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 2),
  );

  test('el JSON conserva el formato guardado y no incluye pinned', () {
    expect(NoteDto.fromEntity(entity).toJson(), {
      'id': '1',
      'title': 'Mercado',
      'content': [
        {'id': 'a', 'content': 'Pan', 'completed': true},
      ],
      'createdAt': DateTime(2026, 1, 1).toIso8601String(),
      'updatedAt': DateTime(2026, 1, 2).toIso8601String(),
    });
  });

  test('de entidad a JSON y de vuelta conserva los datos', () {
    final json = NoteDto.fromEntity(entity).toJson();

    final result = NoteDto.fromJson(json).toEntity(pinned: false);

    expect(result.id, '1');
    expect(result.title, 'Mercado');
    expect(result.pinned, isFalse);
    expect(result.createdAt, DateTime(2026, 1, 1));
    expect(result.updatedAt, DateTime(2026, 1, 2));
    expect(result.content.single.id, 'a');
    expect(result.content.single.content, 'Pan');
    expect(result.content.single.completed, isTrue);
  });

  group('notas viejas guardadas como texto', () {
    List<TaskDto> read(String text) => TaskDto.listFromJson('1', text);

    test('un texto vacío, de espacios o de renglones no crea tareas', () {
      expect(read(''), isEmpty);
      expect(read('   '), isEmpty);
      expect(read('\n \n'), isEmpty);
    });

    test('un guion solo queda como texto, sin tratarlo como lista', () {
      expect(read('-').single.content, '-');
    });

    test('marcas de tachado sin texto no marcan la tarea', () {
      final task = read('~~~~').single;
      expect(task.content, '');
      expect(task.completed, isFalse);
    });

    test('solo se completa si todo el renglón está tachado', () {
      expect(read('~~pan~~').single.completed, isTrue);
      expect(read('~~pan~~ y leche').single.completed, isFalse);
    });

    test('cada tarea recibe un id distinto, derivado de la nota', () {
      expect(read('a\nb').map((task) => task.id), ['1_0', '1_1']);
    });
  });

  group('datos inválidos', () {
    test('un content de otro tipo se lee como lista vacía', () {
      expect(TaskDto.listFromJson('1', 5), isEmpty);
    });

    test('una lista de tareas vacía queda vacía', () {
      expect(TaskDto.listFromJson('1', <dynamic>[]), isEmpty);
    });

    test('una tarea sin id o sin texto falla', () {
      expect(
        () => TaskDto.fromJson({'content': 'Pan'}),
        throwsA(isA<TypeError>()),
      );
      expect(() => TaskDto.fromJson({'id': 'a'}), throwsA(isA<TypeError>()));
    });

    test('una nota sin fechas o con fecha inválida falla', () {
      expect(() => NoteDto.fromJson({'id': '1'}), throwsA(isA<TypeError>()));
      expect(
        () => NoteDto.fromJson({
          'id': '1',
          'createdAt': 'ayer',
          'updatedAt': 'hoy',
        }),
        throwsFormatException,
      );
    });

    test('una nota sin título ni contenido se lee vacía', () {
      final result = NoteDto.fromJson({
        'id': '1',
        'createdAt': DateTime(2026).toIso8601String(),
        'updatedAt': DateTime(2026).toIso8601String(),
      }).toEntity(pinned: false);
      expect(result.title, isNull);
      expect(result.content, isEmpty);
      expect(result.isEmpty, isTrue);
    });
  });

  test('una tarea sin completed se lee como pendiente', () {
    expect(TaskDto.fromJson({'id': 'a', 'content': 'Pan'}).completed, isFalse);
  });

  test('un contenido sin tareas ni texto se lee como lista vacía', () {
    expect(TaskDto.listFromJson('1', null), isEmpty);
  });
}

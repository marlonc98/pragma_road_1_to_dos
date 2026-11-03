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

  test('una tarea sin completed se lee como pendiente', () {
    expect(TaskDto.fromJson({'id': 'a', 'content': 'Pan'}).completed, isFalse);
  });

  test('un contenido sin tareas ni texto se lee como lista vacía', () {
    expect(TaskDto.listFromJson('1', null), isEmpty);
  });
}

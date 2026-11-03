import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/entities/task_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

List<TaskEntity> _tasks(
  String noteId,
  List<String> contents, {
  Set<int> completed = const {},
}) => [
  for (final (index, content) in contents.indexed)
    TaskEntity(
      id: '${noteId}_$index',
      content: content,
      completed: completed.contains(index),
    ),
];

final List<NoteEntity> _fakeNotes = [
  NoteEntity(
    id: '1',
    title: 'Lista del mercado',
    content: _tasks(
      '1',
      ['Leche', 'Huevos', 'Pan integral', 'Café', 'Aguacates', 'Tomates'],
      completed: {0, 3},
    ),
    pinned: true,
    createdAt: _daysAgo(10),
    updatedAt: _daysAgo(1),
  ),
  NoteEntity(
    id: '2',
    title: 'Ideas para el fin de semana',
    content: _tasks('2', [
      'Ir al parque',
      'Ver una película',
      'Probar la receta de lasaña',
    ]),
    createdAt: _daysAgo(9),
    updatedAt: _daysAgo(2),
  ),
  NoteEntity(
    id: '3',
    content: _tasks('3', ['Llamar al banco antes del viernes']),
    createdAt: _daysAgo(8),
    updatedAt: _daysAgo(3),
  ),
  NoteEntity(
    id: '4',
    title: 'Contraseña del wifi en la oficina',
    createdAt: _daysAgo(7),
    updatedAt: _daysAgo(4),
  ),
  NoteEntity(
    id: '5',
    title: 'Libros pendientes',
    content: _tasks(
      '5',
      [
        'Clean Architecture',
        'El programador pragmático',
        'Refactoring',
        'Domain-Driven Design',
      ],
      completed: {0},
    ),
    pinned: true,
    createdAt: _daysAgo(6),
    updatedAt: _daysAgo(5),
  ),
  NoteEntity(
    id: '6',
    content: _tasks('6', [
      'Revisar los pull requests pendientes',
      'Responder los comentarios del equipo antes de la daily',
    ]),
    createdAt: _daysAgo(5),
    updatedAt: _daysAgo(5),
  ),
  NoteEntity(
    id: '7',
    title: 'Cumpleaños de mamá',
    content: _tasks('7', ['Comprar flores para el 12 de noviembre']),
    createdAt: _daysAgo(4),
    updatedAt: _daysAgo(6),
  ),
  NoteEntity(
    id: '8',
    title: 'Rutina gimnasio',
    content: _tasks(
      '8',
      ['Lunes: pierna', 'Miércoles: espalda', 'Viernes: pecho y brazo'],
      completed: {0, 1},
    ),
    createdAt: _daysAgo(3),
    updatedAt: _daysAgo(7),
  ),
  ..._generatedNotes(60),
];

const _generatedTitles = [
  'Pendientes del trabajo',
  'Receta',
  'Ideas',
  'Compras',
  'Viaje',
  'Reunión',
];

const _generatedContents = [
  ['Revisar correos', 'Responder lo urgente'],
  ['Comprar pan', 'Leche', 'Huevos'],
  ['Leer un capítulo antes de dormir'],
  ['Agendar cita con el médico', 'Llevar los exámenes'],
  ['Paso 1', 'Paso 2', 'Paso 3', 'Paso 4', 'Paso 5'],
];

List<NoteEntity> _generatedNotes(int count) => List.generate(count, (index) {
  final number = index + 1;
  final id = 'generated_$number';
  final hasTitle = index % 3 != 2;
  final hasContent = index % 4 != 3;
  return NoteEntity(
    id: id,
    title: hasTitle
        ? '${_generatedTitles[index % _generatedTitles.length]} $number'
        : null,
    content: hasContent || !hasTitle
        ? _tasks(
            id,
            _generatedContents[index % _generatedContents.length],
            completed: {if (index.isEven) 0},
          )
        : const [],
    createdAt: _daysAgo(10 + number),
    updatedAt: _daysAgo(10 + number),
  );
});

class NoteRepositoryMock extends NoteRepository {
  final Duration _delay = const Duration(milliseconds: 400);

  @override
  Future<AsyncState<void>> addNote(NoteEntity note) async {
    await Future.delayed(_delay);
    _fakeNotes.add(note);
    return AsyncState.success();
  }

  @override
  Future<AsyncState<void>> updateNote(NoteEntity note) async {
    await Future.delayed(_delay);
    final index = _fakeNotes.indexWhere((element) => element.id == note.id);
    if (index == -1) return AsyncState.fromError(Exception());
    _fakeNotes[index] = note;
    return AsyncState.success();
  }

  @override
  Future<AsyncState<void>> deleteNote(String id) async {
    await Future.delayed(_delay);
    _fakeNotes.removeWhere((element) => element.id == id);
    return AsyncState.success();
  }

  @override
  Future<AsyncState<List<NoteEntity>>> getNotes() async {
    await Future.delayed(_delay);
    return AsyncState.success(
      data: [..._fakeNotes]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
    );
  }

  @override
  Future<AsyncState<void>> setPinned(String id, bool pinned) async {
    await Future.delayed(_delay);
    final index = _fakeNotes.indexWhere((element) => element.id == id);
    if (index == -1) {
      return AsyncState.fromError(ErrorsConstants.noteNotFound);
    }
    _fakeNotes[index] = _fakeNotes[index].copyWith(pinned: pinned);
    return AsyncState.success();
  }

  @override
  Future<AsyncState<int>> countPinnedNotes() async {
    return AsyncState.success(
      data: _fakeNotes.where((note) => note.pinned).length,
    );
  }
}

import 'package:gestor_tareas_personales/domain/constants/errors_constants.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/core/search_result.dart';
import 'package:gestor_tareas_personales/domain/repositories/note_repository.dart';

DateTime _daysAgo(int days) => DateTime.now().subtract(Duration(days: days));

final List<NoteEntity> _fakeNotes = [
  NoteEntity(
    id: '1',
    title: 'Lista del mercado',
    content: 'Leche\nHuevos\nPan integral\nCafé\nAguacates\nTomates',
    pinned: true,
    createdAt: _daysAgo(10),
    updatedAt: _daysAgo(1),
  ),
  NoteEntity(
    id: '2',
    title: 'Ideas para el fin de semana',
    content: 'Ir al parque, ver una película y probar la receta de lasaña.',
    createdAt: _daysAgo(9),
    updatedAt: _daysAgo(2),
  ),
  NoteEntity(
    id: '3',
    content: 'Llamar al banco antes del viernes',
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
    content: 'Clean Architecture\nEl programador pragmático\nRefactoring\nDomain-Driven Design',
    pinned: true,
    createdAt: _daysAgo(6),
    updatedAt: _daysAgo(5),
  ),
  NoteEntity(
    id: '6',
    content: 'Recordar revisar los pull requests pendientes y responder los comentarios del equipo antes de la daily.',
    createdAt: _daysAgo(5),
    updatedAt: _daysAgo(5),
  ),
  NoteEntity(
    id: '7',
    title: 'Cumpleaños de mamá',
    content: '12 de noviembre, comprar flores',
    createdAt: _daysAgo(4),
    updatedAt: _daysAgo(6),
  ),
  NoteEntity(
    id: '8',
    title: 'Rutina gimnasio',
    content: 'Lunes: pierna\nMiércoles: espalda\nViernes: pecho y brazo',
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
  'Revisar correos y responder lo urgente',
  'Comprar pan\nLeche\nHuevos',
  'Leer un capítulo antes de dormir',
  'Agendar cita con el médico para la próxima semana y llevar los exámenes',
  'Paso 1\nPaso 2\nPaso 3\nPaso 4\nPaso 5',
];

List<NoteEntity> _generatedNotes(int count) => List.generate(count, (index) {
  final number = index + 1;
  final hasTitle = index % 3 != 2;
  final hasContent = index % 4 != 3;
  return NoteEntity(
    id: 'generated_$number',
    title: hasTitle
        ? '${_generatedTitles[index % _generatedTitles.length]} $number'
        : null,
    content: hasContent || !hasTitle
        ? _generatedContents[index % _generatedContents.length]
        : null,
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
  Future<AsyncState<List<NoteEntity>>> getPinnedNotes({
    String? query,
  }) async {
    await Future.delayed(_delay);
    return AsyncState.success(
      data: _search(query).where((note) => note.pinned).toList(),
    );
  }

  @override
  Future<AsyncState<SearchResult<NoteEntity>>> getNotes({
    required int page,
    required int itemsPerPage,
    String? query,
  }) async {
    await Future.delayed(_delay);
    final notes = _search(query).where((note) => !note.pinned).toList();
    return AsyncState.success(
      data: SearchResult(
        currentPage: page,
        totalItems: notes.length,
        data: notes.skip((page - 1) * itemsPerPage).take(itemsPerPage).toList(),
        itemsPerPage: itemsPerPage,
        lastpage: (notes.length / itemsPerPage).ceil(),
      ),
    );
  }

  List<NoteEntity> _search(String? query) {
    final search = query?.toLowerCase() ?? '';
    return _fakeNotes
        .where(
          (note) =>
              search.isEmpty ||
              (note.title?.toLowerCase().contains(search) ?? false) ||
              (note.content?.toLowerCase().contains(search) ?? false),
        )
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<AsyncState<NoteEntity>> getNoteById(String id) async {
    await Future.delayed(_delay);
    final index = _fakeNotes.indexWhere((element) => element.id == id);
    if (index == -1) {
      return AsyncState.fromError(ErrorsConstants.noteNotFound);
    }
    return AsyncState.success(data: _fakeNotes[index]);
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

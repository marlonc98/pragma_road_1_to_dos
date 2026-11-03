/// Nota del usuario, al estilo de Google Keep.
///
/// Puede tener solo título, solo contenido o ambos, pero nunca ninguno de los
/// dos: una nota vacía ([isEmpty]) no se guarda.
class NoteEntity {
  final String id;

  /// Primer renglón del editor. Se muestra más grande.
  final String? title;

  /// Resto del texto después del título. Puede traer marcas Markdown
  /// (`**negrita**`, `_cursiva_`, `~~tachado~~`, `- ` para listas).
  final String? content;

  /// Si la nota está fijada arriba de la lista. Máximo 5 notas fijadas.
  final bool pinned;

  /// Fecha de creación. No cambia al editar.
  final DateTime createdAt;

  /// Fecha de la última edición. Las notas no fijadas se ordenan por este
  /// campo, de la más reciente a la más antigua.
  final DateTime updatedAt;

  NoteEntity({
    required this.id,
    this.title,
    this.content,
    this.pinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Si el título tiene algo más que espacios.
  bool get hasTitle => title?.trim().isNotEmpty ?? false;

  /// Si el contenido tiene algo más que espacios.
  bool get hasContent => content?.trim().isNotEmpty ?? false;

  /// Si la nota no tiene título ni contenido. Una nota vacía no se guarda, y
  /// si se vacía al editarla, se borra al salir del editor.
  bool get isEmpty => !hasTitle && !hasContent;

  /// Copia la nota cambiando solo los campos indicados. `id` y `createdAt`
  /// nunca cambian.
  NoteEntity copyWith({
    String? title,
    String? content,
    bool? pinned,
    DateTime? updatedAt,
  }) {
    return NoteEntity(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      pinned: pinned ?? this.pinned,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

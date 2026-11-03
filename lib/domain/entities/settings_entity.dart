/// Preferencias del usuario.
class SettingsEntity {
  /// Si los cambios del editor se guardan solos. Si no, hay que tocar Guardar.
  final bool autoSave;

  /// Si las listas abren en vista previa y hay que tocar Editar para
  /// modificarlas. Si no, abren listas para editar.
  final bool requireEditMode;

  const SettingsEntity({this.autoSave = true, this.requireEditMode = true});

  SettingsEntity copyWith({bool? autoSave, bool? requireEditMode}) {
    return SettingsEntity(
      autoSave: autoSave ?? this.autoSave,
      requireEditMode: requireEditMode ?? this.requireEditMode,
    );
  }
}

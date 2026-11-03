import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/domain/states/settings_state.dart';

class SettingsStateImpl extends Notifier<SettingsEntity>
    implements SettingsState {
  @override
  SettingsEntity build() => const SettingsEntity();

  @override
  void setSettings(SettingsEntity settings) => state = settings;
}

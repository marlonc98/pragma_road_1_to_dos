import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/settings_entity.dart';
import 'package:gestor_tareas_personales/presentation/core/view_model.dart';
import 'package:gestor_tareas_personales/presentation/pages/settings/settings_page.dart';

class SettingsPageViewModel extends ViewModel<SettingsPage> {
  SettingsPageViewModel({
    required super.context,
    required super.widget,
    required super.ref,
    required super.isMounted,
  });

  SettingsEntity get _settings => ref.read(settingsStateProvider);

  Future<void> handleAutoSaveChanged(bool value) =>
      _save(_settings.copyWith(autoSave: value));

  Future<void> handleRequireEditModeChanged(bool value) =>
      _save(_settings.copyWith(requireEditMode: value));

  Future<void> _save(SettingsEntity settings) async {
    final response = await ref
        .read(saveSettingsUseCaseProvider)
        .saveSettings(settings);
    if (response.isSuccess || !mounted) return;
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(i18n(response.error ?? ''))));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/settings/settings_page_view_model.dart';

class SettingsPageScreen extends ConsumerWidget {
  final SettingsPageViewModel vm;
  const SettingsPageScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    final settings = ref.watch(settingsStateProvider);
    return Scaffold(
      appBar: AppBar(title: Text(i18n(TextConstants.settingsTitle))),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(i18n(TextConstants.settingsAutoSave)),
            subtitle: Text(i18n(TextConstants.settingsAutoSaveDescription)),
            value: settings.autoSave,
            onChanged: vm.handleAutoSaveChanged,
          ),
          SwitchListTile(
            title: Text(i18n(TextConstants.settingsRequireEditMode)),
            subtitle: Text(
              i18n(TextConstants.settingsRequireEditModeDescription),
            ),
            value: settings.requireEditMode,
            onChanged: vm.handleRequireEditModeChanged,
          ),
        ],
      ),
    );
  }
}

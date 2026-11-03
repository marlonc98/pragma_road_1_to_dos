import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/presentation/core/stf_view_model_adapter.dart';
import 'package:gestor_tareas_personales/presentation/pages/settings/settings_page_screen.dart';
import 'package:gestor_tareas_personales/presentation/pages/settings/settings_page_view_model.dart';

class SettingsPage extends StatefulWidget {
  static const String route = '/settings';

  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return StfViewModelAdapter(
      create: (ref) => SettingsPageViewModel(
        context: context,
        widget: widget,
        ref: ref,
        isMounted: () => mounted,
      ),
      builder: (context, viewModel) => SettingsPageScreen(vm: viewModel),
    );
  }
}

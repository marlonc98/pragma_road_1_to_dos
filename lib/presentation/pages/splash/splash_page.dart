import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/presentation/pages/splash/splash_page_screen.dart';
import 'package:gestor_tareas_personales/presentation/pages/splash/splash_page_view_model.dart';
import 'package:gestor_tareas_personales/presentation/core/stf_view_model_adapter.dart';

class SplashPage extends StatefulWidget {
  static const String route = '/splash';
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  Widget build(BuildContext context) {
    return StfViewModelAdapter(
      create: (ref) => SplashPageViewModel(
        context: context,
        widget: widget,
        ref: ref,
        isMounted: () => mounted,
      ),
      builder: (context, viewModel) => SplashPageScreen(vm: viewModel),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/flavors/flavors.dart';
import 'package:gestor_tareas_personales/presentation/router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: F.title, routerConfig: router);
  }
}

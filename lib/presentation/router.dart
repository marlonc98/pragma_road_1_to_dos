import 'package:go_router/go_router.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/splash/splash_page.dart';

final router = GoRouter(
  initialLocation: SplashPage.route,
  routes: [
    GoRoute(
      path: SplashPage.route,
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: NotesPage.route,
      builder: (context, state) => const NotesPage(),
    ),
    GoRoute(
      path: NoteEditorPage.route,
      builder: (context, state) =>
          NoteEditorPage(note: state.extra as NoteEntity?),
    ),
  ],
);

import 'package:go_router/go_router.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page.dart';
import 'package:gestor_tareas_personales/presentation/pages/splash/splash_page.dart';
import 'package:gestor_tareas_personales/presentation/core/view_model.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashPageViewModel extends ViewModel<SplashPage> {
  SplashPageViewModel({
    required super.context,
    required super.widget,
    required super.ref,
    required super.isMounted,
  }) {
    _loadVersionAndBuildNumber();
    _load();
  }

  PackageInfo? packageInfo;

  Future<void> _loadVersionAndBuildNumber() async {
    packageInfo = await PackageInfo.fromPlatform();
    notifyListeners();
  }

  Future<void> _load() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 1200)),
      ref.read(loadUseCaseProvider).call(),
    ]);
    if (mounted) {
      // ignore: use_build_context_synchronously
      context.go(NotesPage.route);
    }
  }
}

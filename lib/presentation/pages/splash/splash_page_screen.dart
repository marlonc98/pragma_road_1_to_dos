import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/splash/splash_page_view_model.dart';

class SplashPageScreen extends ConsumerWidget {
  final SplashPageViewModel vm;
  const SplashPageScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.5 - 240),
              Text(
                i18n(TextConstants.splashPageTitle),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 4),
              if (vm.packageInfo != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Text(
                    i18n(
                      TextConstants.versionAndBuild,
                      values: {
                        "version": vm.packageInfo!.version,
                        "build": vm.packageInfo!.buildNumber,
                      },
                    ),
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

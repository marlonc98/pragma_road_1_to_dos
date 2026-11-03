import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/widgets/buttons/button_widget.dart';

class ErrorLoadingWidget extends ConsumerWidget {
  final Function()? onRetry;
  final String? error;

  const ErrorLoadingWidget({super.key, required this.onRetry, this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              error ?? i18n(TextConstants.errorLoadingWidgetAnErrorOccurred),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.5,
                child: ButtonWidget(
                  onTap: onRetry!,
                  text: i18n(TextConstants.retry),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/widgets/buttons/button_widget.dart';

class NoResultsWidget extends ConsumerWidget {
  final Function()? onRetry;
  final String? message;
  final String? retryText;
  final String? title;
  final Widget? icon;
  final ButtonType buttonType;
  const NoResultsWidget({
    super.key,
    this.onRetry,
    this.message,
    this.retryText,
    this.title,
    this.icon,
    this.buttonType = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(height: 20)],
            if (title != null && title!.isNotEmpty) ...[
              Text(
                title!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: 320,
              child: Text(
                (message != null && message!.isNotEmpty)
                    ? message!
                    : i18n(TextConstants.noResultsWidgetDescription),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ),
            const SizedBox(height: 20),
            if (onRetry != null)
              Container(
                alignment: Alignment.center,
                child: ButtonWidget(
                  fitContent: true,
                  type: buttonType,
                  onTap: onRetry!,
                  text: retryText ?? i18n(TextConstants.noResultsWidgetButton),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

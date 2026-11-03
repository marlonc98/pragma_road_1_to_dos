import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/widgets/buttons/button_widget.dart';

class NoResultsSmallWidget extends ConsumerWidget {
  final Function()? onRetry;
  final String? message;
  final String? retryText;
  final String? title;
  final Widget? icon;

  const NoResultsSmallWidget({
    super.key,
    this.onRetry,
    this.message,
    this.retryText,
    this.title,
    this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    return ClipRect(
      child: OverflowBox(
        minHeight: 0,
        maxHeight: double.infinity,
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ?icon,
              const SizedBox(height: 6),
              Text(
                title ?? i18n(TextConstants.noResultsWidgetTitle),
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: Colors.grey, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  message!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                ButtonWidget(
                  fitContent: true,
                  onTap: onRetry!,
                  text: retryText ?? i18n(TextConstants.noResultsWidgetButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

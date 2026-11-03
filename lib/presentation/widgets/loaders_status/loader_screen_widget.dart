import 'package:flutter/material.dart';
import 'package:gestor_tareas_personales/domain/core/async_state.dart';
import 'package:gestor_tareas_personales/domain/core/search_result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/error_loading_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/loading_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/no_results_small_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/no_results_widget.dart';

Widget? getIconNoResults({
  required BuildContext context,
  IconData? iconNoResultsIcon,
}) {
  if (iconNoResultsIcon == null) return null;
  return Icon(
    iconNoResultsIcon,
    size: 50,
    color: Theme.of(context).colorScheme.outline,
  );
}

enum FullSizeOptions { inExpanded, inContainer, notFullSize }

class LoaderScreenWidget<T> extends ConsumerWidget {
  final AsyncState<T> status;
  final bool noResultsScreen;
  final bool noResultsSmall;
  final FullSizeOptions fullSize;
  final bool allowNull;
  final bool padBottom;
  final bool customNoResultsOperation;

  final String? errorTitle;
  final String? retryMessage;
  final Function()? onRetry;
  final Widget? icon;
  final String? buttonRetry;

  final String? messageNoResults;
  final String? buttonTextNoResults;
  final Function()? onRetryNoResults;
  final IconData? iconNoResultsIcon;
  final Widget? customNoResults;

  final Widget Function(BuildContext context, T data) builder;

  const LoaderScreenWidget({
    super.key,
    this.errorTitle,
    this.noResultsScreen = false,
    this.noResultsSmall = false,
    this.icon,
    required this.status,
    required this.builder,
    this.onRetry,
    this.retryMessage,
    this.messageNoResults,
    this.buttonTextNoResults,
    this.onRetryNoResults,
    this.buttonRetry,
    this.fullSize = FullSizeOptions.inContainer,
    this.iconNoResultsIcon,
    this.allowNull = false,
    this.padBottom = true,
    this.customNoResults,
    this.customNoResultsOperation = false,
  });

  Widget _containerFullSize(Widget child, BuildContext context, bool isNull) {
    if ((status.isSuccess) && !isNull || allowNull) {
      return child;
    }
    if (fullSize == FullSizeOptions.inExpanded) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - 150 - kToolbarHeight - 100,
        child: Center(
          child: Padding(
            padding: EdgeInsetsGeometry.only(bottom: padBottom ? 150 : 0),
            child: child,
          ),
        ),
      );
    } else if (fullSize == FullSizeOptions.notFullSize) {
      return Center(
        child: Padding(
          padding: EdgeInsetsGeometry.only(bottom: padBottom ? 150 : 0),
          child: child,
        ),
      );
    }
    if (fullSize == FullSizeOptions.inContainer) {
      return SizedBox.expand(
        child: Center(
          child: Padding(
            padding: EdgeInsetsGeometry.only(bottom: 150),
            child: child,
          ),
        ),
      );
    }
    return Padding(
      padding: EdgeInsetsGeometry.only(bottom: padBottom ? 150 : 0),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    final T? data = status.data;
    final dataIsNull =
        data == null ||
        (data is SearchResult ? data.isEmpty : false) ||
        (data is List ? data.isEmpty : false) ||
        (data is Map ? data.isEmpty : false);

    if (status.isNotStarted) return SizedBox.shrink();
    if (status.isLoading) {
      return _containerFullSize(const LoadingWidget(), context, dataIsNull);
    } else if (noResultsScreen &&
        (status.isSuccess && (dataIsNull || customNoResultsOperation))) {
      return _containerFullSize(
        customNoResults ??
            (noResultsSmall
                ? NoResultsSmallWidget(
                    onRetry: onRetryNoResults ?? onRetry,
                    message: messageNoResults,
                    retryText: buttonTextNoResults,
                    icon: getIconNoResults(
                      context: context,
                      iconNoResultsIcon: iconNoResultsIcon,
                    ),
                  )
                : NoResultsWidget(
                    onRetry: onRetryNoResults ?? onRetry,
                    message: messageNoResults,
                    retryText: buttonTextNoResults,
                    icon: getIconNoResults(
                      context: context,
                      iconNoResultsIcon: iconNoResultsIcon,
                    ),
                  )),
        context,
        dataIsNull,
      );
    } else if (status.isError ||
        (!allowNull && (dataIsNull || customNoResultsOperation))) {
      return _containerFullSize(
        ErrorLoadingWidget(
          onRetry: onRetry,
          error: status.error != null ? i18n(status.error!) : errorTitle,
        ),
        context,
        dataIsNull,
      );
    }
    assert(
      data != null || allowNull,
      'LoaderScreenWidget: builder reached with null data; use a nullable T '
      '(e.g. LoaderScreenWidget<Cat?>) when allowNull is true.',
    );
    return builder(context, data as T);
  }
}

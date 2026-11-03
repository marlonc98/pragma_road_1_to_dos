import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/presentation/core/view_model.dart';

class StfViewModelAdapter<T extends ViewModel> extends ConsumerStatefulWidget {
  final T Function(WidgetRef ref) create;
  final Widget Function(BuildContext context, T viewModel) builder;

  const StfViewModelAdapter({
    super.key,
    required this.create,
    required this.builder,
  });

  @override
  ConsumerState<StfViewModelAdapter<T>> createState() =>
      _StfViewModelAdapterState<T>();
}

class _StfViewModelAdapterState<T extends ViewModel>
    extends ConsumerState<StfViewModelAdapter<T>> {
  late final T viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = widget.create(ref);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) => widget.builder(context, viewModel),
    );
  }
}

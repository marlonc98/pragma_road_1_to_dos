import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page_view_model.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/widgets/markdown_toolbar_widget.dart';

class NoteEditorPageScreen extends ConsumerWidget {
  final NoteEditorPageViewModel vm;
  const NoteEditorPageScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyLarge?.copyWith(height: 1.5);
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );
    vm.controller
      ..titleStyle = titleStyle
      ..markerStyle = TextStyle(color: theme.colorScheme.outline);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) vm.handleExit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: vm.handleExit),
          title: Text(
            switch (vm.saveStatus) {
              SaveStatus.idle => '',
              SaveStatus.saving => i18n(TextConstants.noteEditorSaving),
              SaveStatus.saved => i18n(TextConstants.noteEditorSaved),
            },
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              if (vm.isLoading) const LinearProgressIndicator(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: TextField(
                    controller: vm.controller,
                    readOnly: vm.isLoading,
                    autofocus: vm.isNewNote,
                    expands: true,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    autocorrect: false,
                    smartDashesType: SmartDashesType.disabled,
                    smartQuotesType: SmartQuotesType.disabled,
                    textAlignVertical: TextAlignVertical.top,
                    style: bodyStyle,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: i18n(TextConstants.noteEditorHint),
                      hintStyle: titleStyle?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              MarkdownToolbarWidget(
                onBold: vm.handleBold,
                onItalic: vm.handleItalic,
                onStrikethrough: vm.handleStrikethrough,
                onList: vm.handleList,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

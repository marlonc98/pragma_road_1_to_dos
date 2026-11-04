import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/note_editor_page_view_model.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/widgets/markdown_toolbar_widget.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/controllers/note_editing_controller.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/widgets/task_preview_row_widget.dart';
import 'package:gestor_tareas_personales/presentation/pages/note_editor/widgets/task_row_widget.dart';

class NoteEditorPageScreen extends ConsumerWidget {
  final NoteEditorPageViewModel vm;
  const NoteEditorPageScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

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
          actions: [
            if (!vm.isEditing)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: i18n(TextConstants.noteEditorEdit),
                onPressed: vm.handleEdit,
              ),
            if (vm.showSaveButton)
              TextButton.icon(
                icon: const Icon(Icons.check),
                label: Text(i18n(TextConstants.noteEditorSave)),
                onPressed: vm.handleSave,
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                // Todas las filas se construyen para que el Form las valide
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                  child: Form(
                    key: vm.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (vm.isEditing)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _buildTitleField(i18n, theme, titleStyle),
                          )
                        else if (vm.title != null)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                            child: Text.rich(
                              NoteEditingController.formattedSpan(vm.title!),
                              style: titleStyle,
                            ),
                          ),
                        for (final row in vm.taskRows)
                          if (vm.isEditing)
                            TaskRowWidget(
                              key: ValueKey(row.id),
                              row: row,
                              validator: vm.validateTask,
                              onToggle: () => vm.handleToggleTask(row),
                              onEdited: vm.handleTaskEdited,
                              onSubmitted: () => vm.handleTaskSubmitted(row),
                              onDelete: () => vm.handleDeleteTask(row),
                            )
                          else
                            TaskPreviewRowWidget(
                              key: ValueKey(row.id),
                              row: row,
                              onToggle: () => vm.handleToggleTask(row),
                            ),
                        if (vm.isEditing)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.add),
                              label: Text(
                                i18n(TextConstants.noteEditorAddTask),
                              ),
                              onPressed: vm.handleAddTask,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (vm.isEditing)
                MarkdownToolbarWidget(
                  onBold: vm.handleBold,
                  onItalic: vm.handleItalic,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleField(
    String Function(String, {Map<String, dynamic>? values}) i18n,
    ThemeData theme,
    TextStyle? titleStyle,
  ) {
    return TextFormField(
      controller: vm.titleController,
      focusNode: vm.titleFocusNode,
      validator: vm.validateTitle,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofocus: vm.isNewNote,
      maxLines: null,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      autocorrect: false,
      smartDashesType: SmartDashesType.disabled,
      smartQuotesType: SmartQuotesType.disabled,
      inputFormatters: [
        FilteringTextInputFormatter.deny('\n', replacementString: ' '),
      ],
      // Sin esto, Enter le pasa el foco al siguiente botón
      onEditingComplete: () {},
      onFieldSubmitted: (_) => vm.handleTitleSubmitted(),
      style: titleStyle,
      decoration: InputDecoration(
        border: InputBorder.none,
        hintText: i18n(TextConstants.noteEditorHint),
        hintStyle: WidgetStateTextStyle.resolveWith(
          (states) => (titleStyle ?? const TextStyle()).copyWith(
            color: states.contains(WidgetState.error)
                ? theme.colorScheme.error
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

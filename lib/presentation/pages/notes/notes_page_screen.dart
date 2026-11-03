import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page_view_model.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/notes_grid_widget.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/notes_search_bar_widget.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/note_preview_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/loader_screen_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/no_results_widget.dart';

class NotesPageScreen extends ConsumerWidget {
  final NotesPageViewModel vm;
  const NotesPageScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
    final notes = ref.watch(notesStateProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: i18n(TextConstants.notesCreate),
        onPressed: vm.handleCreateNote,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: NotesSearchBarWidget(
                      controller: vm.searchController,
                      hintText: i18n(TextConstants.notesSearchHint),
                      onChanged: vm.handleSearchChanged,
                      onClear: vm.handleClearSearch,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: i18n(TextConstants.notesSettings),
                    onPressed: vm.handleOpenSettings,
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.handleLoadNotes,
                child: LoaderScreenWidget<List<NoteEntity>?>(
                  status: notes,
                  allowNull: true,
                  onRetry: vm.handleLoadNotes,
                  builder: (context, data) =>
                      _buildNotes(context, i18n, data ?? []),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotes(
    BuildContext context,
    String Function(String, {Map<String, dynamic>? values}) i18n,
    List<NoteEntity> notes,
  ) {
    final visible = vm.visibleNotes(notes);
    final pinned = visible.where((note) => note.pinned).toList();
    final others = visible.where((note) => !note.pinned).toList();
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (visible.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmpty(i18n)),
        if (pinned.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, i18n(TextConstants.notesPinned)),
                  NotesGridWidget(
                    notes: pinned,
                    onTap: vm.handleOpenNote,
                    onLongPress: vm.handleNoteOptions,
                  ),
                  if (others.isNotEmpty)
                    _buildSectionTitle(
                      context,
                      i18n(TextConstants.notesOthers),
                    ),
                ],
              ),
            ),
          ),
        if (others.isNotEmpty)
          SliverPadding(
            padding: EdgeInsets.fromLTRB(12, pinned.isEmpty ? 8 : 0, 12, 96),
            sliver: SliverMasonryGrid.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childCount: others.length,
              itemBuilder: (context, index) => NotePreviewWidget(
                note: others[index],
                onTap: () => vm.handleOpenNote(others[index]),
                onLongPress: () => vm.handleNoteOptions(others[index]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty(
    String Function(String, {Map<String, dynamic>? values}) i18n,
  ) {
    final isSearching = vm.query.isNotEmpty;
    return NoResultsWidget(
      message: i18n(
        isSearching ? TextConstants.notesNoResults : TextConstants.notesEmpty,
      ),
      icon: Builder(
        builder: (context) => Icon(
          isSearching ? Icons.search_off : Icons.lightbulb_outline,
          size: 50,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      onRetry: isSearching ? vm.handleClearSearch : vm.handleCreateNote,
      retryText: i18n(
        isSearching
            ? TextConstants.notesClearSearch
            : TextConstants.notesCreate,
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

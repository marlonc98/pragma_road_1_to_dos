import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:gestor_tareas_personales/dependency_injection.dart';
import 'package:gestor_tareas_personales/domain/entities/note_entity.dart';
import 'package:gestor_tareas_personales/presentation/constants/text_constants.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/notes_page_view_model.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/notes_grid_widget.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/notes_search_bar_widget.dart';
import 'package:gestor_tareas_personales/presentation/pages/notes/widgets/note_preview_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/error_loading_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/loading_widget.dart';
import 'package:gestor_tareas_personales/presentation/widgets/loaders_status/no_results_widget.dart';

class NotesPageScreen extends ConsumerWidget {
  final NotesPageViewModel vm;
  const NotesPageScreen({super.key, required this.vm});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localizationStateProvider);
    final i18n = ref.read(localizationStateProvider.notifier).translate;
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
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: NotesSearchBarWidget(
                controller: vm.searchController,
                hintText: i18n(TextConstants.notesSearchHint),
                onChanged: vm.handleSearchChanged,
                onClear: vm.handleClearSearch,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: vm.handleLoadNotes,
                child: PagingListener<int, NoteEntity>(
                  controller: vm.pagingController,
                  builder: (context, state, fetchNextPage) =>
                      _buildNotes(context, i18n, state, fetchNextPage),
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
    PagingState<int, NoteEntity> state,
    VoidCallback fetchNextPage,
  ) {
    final pinned = vm.pinnedNotes.data ?? [];
    final hasOthers = state.items?.isNotEmpty ?? false;
    return CustomScrollView(
      slivers: [
        if (vm.pinnedNotes.isError)
          SliverToBoxAdapter(
            child: ErrorLoadingWidget(
              onRetry: vm.handleRetry,
              error: i18n(vm.pinnedNotes.error ?? ''),
            ),
          ),
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
                  if (hasOthers)
                    _buildSectionTitle(
                      context,
                      i18n(TextConstants.notesOthers),
                    ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(12, pinned.isEmpty ? 8 : 0, 12, 96),
          sliver: PagedSliverMasonryGrid<int, NoteEntity>.count(
            state: state,
            fetchNextPage: fetchNextPage,
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            builderDelegate: PagedChildBuilderDelegate<NoteEntity>(
              itemBuilder: (context, note, index) => NotePreviewWidget(
                note: note,
                onTap: () => vm.handleOpenNote(note),
                onLongPress: () => vm.handleNoteOptions(note),
              ),
              firstPageProgressIndicatorBuilder: (context) =>
                  const LoadingWidget(),
              firstPageErrorIndicatorBuilder: (context) => ErrorLoadingWidget(
                onRetry: vm.handleRetry,
                error: state.error?.toString(),
              ),
              noItemsFoundIndicatorBuilder: (context) =>
                  pinned.isNotEmpty || vm.pinnedNotes.isLoading
                  ? const SizedBox.shrink()
                  : _buildEmpty(i18n),
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

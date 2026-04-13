import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/main_tab_swipe_scope.dart';
import '../../../shared/widgets/category_accent_chips.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_category_repository.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';
import 'note_card.dart';
import 'note_categories_screen.dart';
import 'note_comments_sheet.dart';
import 'note_form_dialog.dart';
import 'note_quick_capture_sheet.dart';

enum NotesScope { all, personal, family }

final notesScopeProvider = StateProvider<NotesScope>((ref) => NotesScope.family);
final _notesArchivedProvider = StateProvider<bool>((ref) => false);
final _notesCategoryIdProvider = StateProvider<int?>((ref) => null);
final _notesSearchQueryProvider = StateProvider<String>((ref) => '');

/// One list per scope so [TabBarView] keeps the correct data while swiping.
final notesForScopeProvider =
    FutureProvider.family<List<Note>, NotesScope>((ref, scope) {
  final archived = ref.watch(_notesArchivedProvider);
  final catId = ref.watch(_notesCategoryIdProvider);
  final search = ref.watch(_notesSearchQueryProvider);
  final scopeStr = switch (scope) {
    NotesScope.all => 'all',
    NotesScope.personal => 'personal',
    NotesScope.family => 'family',
  };
  return ref.watch(noteRepositoryProvider).getNotes(
        scope: scopeStr,
        categoryId: catId,
        search: search.isEmpty ? null : search,
        isArchived: archived,
      );
});

final notesListProvider = FutureProvider<List<Note>>((ref) async {
  final scope = ref.watch(notesScopeProvider);
  return ref.watch(notesForScopeProvider(scope).future);
});

void invalidateAllNotesScopes(WidgetRef ref) {
  for (final s in NotesScope.values) {
    ref.invalidate(notesForScopeProvider(s));
  }
  ref.invalidate(notesListProvider);
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final scope = ref.read(notesScopeProvider);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: switch (scope) {
        NotesScope.all => 0,
        NotesScope.personal => 1,
        NotesScope.family => 2,
      },
    );
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final pending = ref.read(pendingSharedNoteTextProvider);
      if (pending == null || pending.isEmpty) return;
      ref.read(pendingSharedNoteTextProvider.notifier).state = null;
      runQuickNoteCapture(ref, context, pending, askScope: true);
    });
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final next = switch (_tabController.index) {
      0 => NotesScope.all,
      1 => NotesScope.personal,
      _ => NotesScope.family,
    };
    if (ref.read(notesScopeProvider) != next) {
      ref.read(notesScopeProvider.notifier).state = next;
      ref.invalidate(notesForScopeProvider(next));
      ref.invalidate(notesListProvider);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Note? note}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => NoteFormDialog(note: note),
    );
    if (ok == true && mounted) {
      invalidateAllNotesScopes(ref);
      ref.invalidate(noteCategoriesListProvider);
    }
  }

  void _openComments(Note note) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteCommentsSheet(note: note),
    ).then((_) {
      if (mounted) invalidateAllNotesScopes(ref);
    });
  }

  Future<void> _quickInsertFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final raw = data?.text?.trim();
    if (raw == null || raw.isEmpty) {
      if (mounted) {
        showAppToast(context,
            message: 'Zwischenablage ist leer', type: ToastType.warning);
      }
      return;
    }
    if (!mounted) return;
    await runQuickNoteCapture(ref, context, raw, askScope: false);
  }

  Widget _notesBodyForScope(
    NotesScope listScope,
    ThemeData theme,
    bool archived,
  ) {
    final notesAsync = ref.watch(notesForScopeProvider(listScope));
    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return EmptyState(
            icon: Icons.note_alt_outlined,
            title: archived ? 'Archiv leer' : 'Keine Notizen',
            subtitle: archived ? null : 'Tippe auf + um eine Notiz anzulegen',
          );
        }
        final pinned = notes.where((n) => n.isPinned).toList();
        final rest = notes.where((n) => !n.isPinned).toList();

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notesForScopeProvider(listScope));
            ref.invalidate(notesListProvider);
          },
          child: CustomScrollView(
            slivers: [
              if (pinned.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      'Angepinnt',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: NoteCard(
                        note: pinned[i],
                        onRefresh: () {
                          ref.invalidate(notesForScopeProvider(listScope));
                          ref.invalidate(notesListProvider);
                        },
                        onEdit: () => _openForm(note: pinned[i]),
                        onOpenComments: () => _openComments(pinned[i]),
                      ),
                    ),
                    childCount: pinned.length,
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    archived ? 'Archiv' : 'Notizen',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final n = rest[i];
                    return Padding(
                      key: ValueKey('note_${listScope.name}_${n.id}'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: NoteCard(
                        note: n,
                        onRefresh: () {
                          ref.invalidate(notesForScopeProvider(listScope));
                          ref.invalidate(notesListProvider);
                        },
                        onEdit: () => _openForm(note: n),
                        onOpenComments: () => _openComments(n),
                      ),
                    );
                  },
                  childCount: rest.length,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline,
        title: 'Fehler',
        subtitle: e.toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotesScope>(notesScopeProvider, (prev, next) {
      final idx = switch (next) {
        NotesScope.all => 0,
        NotesScope.personal => 1,
        NotesScope.family => 2,
      };
      if (_tabController.index != idx && !_tabController.indexIsChanging) {
        _tabController.animateTo(idx);
      }
    });
    ref.listen<String?>(pendingSharedNoteTextProvider, (previous, next) {
      if (next == null || next.isEmpty) return;
      final captured = next;
      ref.read(pendingSharedNoteTextProvider.notifier).state = null;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await runQuickNoteCapture(ref, context, captured, askScope: true);
      });
    });

    final theme = Theme.of(context);
    final archived = ref.watch(_notesArchivedProvider);
    final selectedCat = ref.watch(_notesCategoryIdProvider);
    final catsAsync = ref.watch(noteCategoriesListProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: const Text('Notizen'),
        actions: [
          IconButton(
            tooltip: 'Aus Zwischenablage',
            icon: const Icon(Icons.content_paste_go_outlined),
            onPressed: _quickInsertFromClipboard,
          ),
          IconButton(
            tooltip: archived ? 'Aktive Notizen' : 'Archiv',
            icon: Icon(archived ? Icons.inventory_2 : Icons.inventory_2_outlined),
            onPressed: () {
              ref.read(_notesArchivedProvider.notifier).state = !archived;
              invalidateAllNotesScopes(ref);
            },
          ),
        ],
      ),
      body: MainTabSwipeScope(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TabBar(
                controller: _tabController,
                onTap: (i) {
                  final next = switch (i) {
                    0 => NotesScope.all,
                    1 => NotesScope.personal,
                    _ => NotesScope.family,
                  };
                  ref.read(notesScopeProvider.notifier).state = next;
                  ref.invalidate(notesForScopeProvider(next));
                  ref.invalidate(notesListProvider);
                },
                tabs: const [
                  Tab(text: 'Alle'),
                  Tab(text: 'Meine'),
                  Tab(text: 'Familie'),
                ],
              ),
            ),
            catsAsync.when(
              data: (cats) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: CategoryFilterStrip(
                          entries: cats
                              .map(
                                (c) => CategoryStripEntry(
                                  id: c.id,
                                  label: '${c.icon} ${c.name}',
                                  colorHex: c.color,
                                ),
                              )
                              .toList(),
                          selectedCategoryId: selectedCat,
                          onCategorySelected: (id) {
                            ref.read(_notesCategoryIdProvider.notifier).state =
                                id;
                            invalidateAllNotesScopes(ref);
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Kategorien verwalten',
                        onPressed: () async {
                          await Navigator.of(context).push<void>(
                            MaterialPageRoute(
                              builder: (_) => const NoteCategoriesScreen(),
                            ),
                          );
                          ref.invalidate(noteCategoriesListProvider);
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 48),
              error: (_, __) => const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Suchen…',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) {
                  ref.read(_notesSearchQueryProvider.notifier).state = v;
                },
              ),
            ),
            Expanded(
              child: MainTabSwipePageEdges(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _notesBodyForScope(NotesScope.all, theme, archived),
                    _notesBodyForScope(NotesScope.personal, theme, archived),
                    _notesBodyForScope(NotesScope.family, theme, archived),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notesFab',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

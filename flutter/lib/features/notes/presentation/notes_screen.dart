import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';
import '../data/note_category_repository.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';
import 'note_card.dart';
import 'note_categories_screen.dart';
import 'note_comments_sheet.dart';
import 'note_form_dialog.dart';
import '../logic/note_quick_capture.dart';

enum NotesScope { all, personal, family }

final notesScopeProvider = StateProvider<NotesScope>((ref) => NotesScope.family);
final _notesArchivedProvider = StateProvider<bool>((ref) => false);
final _notesCategoryIdProvider = StateProvider<int?>((ref) => null);
final _notesSearchQueryProvider = StateProvider<String>((ref) => '');

final _noteCategoriesForTabsProvider =
    FutureProvider((ref) => ref.read(noteCategoryRepositoryProvider).getCategories());

final notesListProvider = FutureProvider<List<Note>>((ref) {
  final scope = ref.watch(notesScopeProvider);
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

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openForm({Note? note}) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => NoteFormDialog(note: note),
    );
    if (ok == true && mounted) {
      ref.invalidate(notesListProvider);
      ref.invalidate(_noteCategoriesForTabsProvider);
    }
  }

  void _openComments(Note note) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteCommentsSheet(note: note),
    ).then((_) {
      if (mounted) ref.invalidate(notesListProvider);
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
    final scope = ref.read(notesScopeProvider);
    final isPersonal = scope == NotesScope.personal;
    try {
      await ref.read(noteRepositoryProvider).createNote(
            buildQuickNotePayload(raw, isPersonal: isPersonal),
          );
      ref.invalidate(notesListProvider);
      ref.invalidate(_noteCategoriesForTabsProvider);
      if (mounted) {
        showAppToast(context,
            message: 'Notiz angelegt', type: ToastType.success);
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _onReorder(List<Note> ordered) async {
    try {
      await ref.read(noteRepositoryProvider).reorderNotes(
            ordered.map((n) => n.id).toList(),
          );
      ref.invalidate(notesListProvider);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notesAsync = ref.watch(notesListProvider);
    final scope = ref.watch(notesScopeProvider);
    final archived = ref.watch(_notesArchivedProvider);
    final selectedCat = ref.watch(_notesCategoryIdProvider);
    final catsAsync = ref.watch(_noteCategoriesForTabsProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(
          'Notizen',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Aus Zwischenablage',
            icon: const Icon(Icons.content_paste_go_outlined),
            onPressed: _quickInsertFromClipboard,
          ),
          IconButton(
            tooltip: archived ? 'Aktive Notizen' : 'Archiv',
            icon: Icon(archived ? Icons.inventory_2 : Icons.inventory_2_outlined),
            onPressed: () =>
                ref.read(_notesArchivedProvider.notifier).state = !archived,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<NotesScope>(
              segments: const [
                ButtonSegment(value: NotesScope.all, label: Text('Alle')),
                ButtonSegment(value: NotesScope.personal, label: Text('Meine')),
                ButtonSegment(value: NotesScope.family, label: Text('Familie')),
              ],
              selected: {scope},
              onSelectionChanged: (s) {
                ref.read(notesScopeProvider.notifier).state = s.first;
                ref.invalidate(notesListProvider);
              },
            ),
          ),
          catsAsync.when(
            data: (cats) {
              final tabs = <Widget>[
                const Tab(text: 'Alle'),
                ...cats.map((c) => Tab(text: '${c.icon} ${c.name}')),
              ];
              var initial = 0;
              if (selectedCat != null) {
                final i = cats.indexWhere((c) => c.id == selectedCat);
                if (i >= 0) initial = i + 1;
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: DefaultTabController(
                        key: ValueKey('nc_$initial'),
                        length: tabs.length,
                        initialIndex: initial.clamp(0, tabs.length - 1),
                        child: Builder(
                          builder: (ctx) => TabBar(
                            isScrollable: true,
                            tabAlignment: TabAlignment.start,
                            onTap: (i) {
                              if (i == 0) {
                                ref.read(_notesCategoryIdProvider.notifier).state =
                                    null;
                              } else {
                                ref.read(_notesCategoryIdProvider.notifier).state =
                                    cats[i - 1].id;
                              }
                              ref.invalidate(notesListProvider);
                            },
                            tabs: tabs,
                          ),
                        ),
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
                        ref.invalidate(_noteCategoriesForTabsProvider);
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
            child: notesAsync.when(
              data: (notes) {
                if (notes.isEmpty) {
                  return EmptyState(
                    icon: Icons.note_alt_outlined,
                    title: archived ? 'Archiv leer' : 'Keine Notizen',
                    subtitle: archived
                        ? null
                        : 'Tippe auf + um eine Notiz anzulegen',
                  );
                }
                final pinned = notes.where((n) => n.isPinned).toList();
                final rest = notes.where((n) => !n.isPinned).toList();

                return RefreshIndicator(
                  onRefresh: () async {
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
                                onRefresh: () =>
                                    ref.invalidate(notesListProvider),
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
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  archived ? 'Archiv' : 'Notizen',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              if (rest.length > 1)
                                Text(
                                  'Zum Sortieren lange ziehen',
                                  style: theme.textTheme.labelSmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                      SliverReorderableList(
                        itemCount: rest.length,
                        onReorder: (oldI, newI) {
                          if (newI > oldI) newI -= 1;
                          final next = List<Note>.from(rest);
                          final item = next.removeAt(oldI);
                          next.insert(newI, item);
                          _onReorder([...pinned, ...next]);
                        },
                        itemBuilder: (ctx, i) {
                          final n = rest[i];
                          return ReorderableDelayedDragStartListener(
                            key: ValueKey('note_${n.id}'),
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: NoteCard(
                                note: n,
                                onRefresh: () =>
                                    ref.invalidate(notesListProvider),
                                onEdit: () => _openForm(note: n),
                                onOpenComments: () => _openComments(n),
                              ),
                            ),
                          );
                        },
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
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notesFab',
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

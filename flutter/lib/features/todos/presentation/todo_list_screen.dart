import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/main_tab_swipe_scope.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../../categories/categories_providers.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart' as cat;
import '../../categories/presentation/categories_screen.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/family_member.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/preferences/todo_preferences.dart';
import '../../../shared/widgets/category_accent_chips.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/todo_completion_control.dart';
import '../../../core/api/api_client.dart';
import 'todo_detail_screen.dart';
import 'todo_form_dialog.dart';
import 'todo_list_refresh.dart';
import 'proposal_sheet.dart';

final _showCompletedProvider = StateProvider<bool>((ref) => false);

enum TodoScope { all, personal, family }

final _scopeProvider = StateProvider<TodoScope>((ref) => TodoScope.all);
final _selectedCategoryIdProvider = StateProvider<int?>((ref) => null);
final _familyViewMemberIdProvider = StateProvider<int?>((ref) => null);

final _membersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  return ref.watch(memberRepositoryProvider).getMembers();
});

/// Per-tab todo list (for [TabBarView]); keeps correct data on each page while swiping.
final todosForScopeProvider =
    FutureProvider.family<List<Todo>, TodoScope>((ref, scope) {
  ref.watch(todoListRefreshTriggerProvider);
  final showCompleted = ref.watch(_showCompletedProvider);
  final categoryId = ref.watch(_selectedCategoryIdProvider);
  final viewMemberId = ref.watch(_familyViewMemberIdProvider);

  final scopeStr = switch (scope) {
    TodoScope.all => 'all',
    TodoScope.personal => 'personal',
    TodoScope.family => 'family',
  };

  return ref.watch(todoRepositoryProvider).getTodos(
        scope: scopeStr,
        viewMemberId: scope == TodoScope.family ? viewMemberId : null,
        completed: showCompleted ? null : false,
        categoryId: categoryId,
      );
});

final todosProvider = FutureProvider<List<Todo>>((ref) async {
  final scope = ref.watch(_scopeProvider);
  return ref.watch(todosForScopeProvider(scope).future);
});

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen>
    with SingleTickerProviderStateMixin {
  final _quickAddController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final scope = ref.read(_scopeProvider);
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: switch (scope) {
        TodoScope.all => 0,
        TodoScope.personal => 1,
        TodoScope.family => 2,
      },
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final i = _tabController.index;
    final next = switch (i) {
      0 => TodoScope.all,
      1 => TodoScope.personal,
      _ => TodoScope.family,
    };
    if (ref.read(_scopeProvider) != next) {
      ref.read(_scopeProvider.notifier).state = next;
      if (next != TodoScope.family) {
        ref.read(_familyViewMemberIdProvider.notifier).state = null;
      }
      ref.invalidate(todosForScopeProvider(next));
      ref.invalidate(todosProvider);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _quickAdd() async {
    final text = _quickAddController.text.trim();
    if (text.isEmpty) return;
    try {
      final scope = ref.read(_scopeProvider);
      final memberId = ref.read(authStateProvider).user?.memberId;

      final data = <String, dynamic>{
        'title': text,
        'is_personal': scope == TodoScope.personal,
      };

      // Default assignment for family todos: current user, so it can be completed.
      if (scope != TodoScope.personal && memberId != null) {
        data['member_ids'] = [memberId];
      }

      await ref.read(todoRepositoryProvider).createTodo(data);
      _quickAddController.clear();
      ref.invalidate(todosForScopeProvider(scope));
      ref.invalidate(todosProvider);
      if (mounted)
        showAppToast(context,
            message: 'Todo erstellt', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted)
        showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _toggleComplete(Todo todo, TodoScope listScope) async {
    final prefs = ref.read(todoPreferencesProvider).valueOrNull ??
        const TodoPreferences();
    if (!todo.completed && todo.parentId == null) {
      if (prefs.requireSubtodosComplete &&
          todo.subtodos.any((s) => !s.completed)) {
        if (mounted) {
          showAppToast(
            context,
            message: 'Bitte zuerst alle Sub-Todos abhaken',
            type: ToastType.warning,
          );
        }
        return;
      }
    }
    try {
      final updated = await ref.read(todoRepositoryProvider).completeTodo(
            todo.id,
            completed: !todo.completed,
          );
      ref.invalidate(todosForScopeProvider(listScope));
      ref.invalidate(todosProvider);
      if (mounted && updated.parentAutoCompleted) {
        showAppToast(
          context,
          message: 'Haupt-Todo wurde automatisch erledigt',
          type: ToastType.success,
        );
      }
    } on ApiException catch (e) {
      if (mounted)
        showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  void _invalidateAllTodoScopes() {
    ref.invalidate(todosForScopeProvider(TodoScope.all));
    ref.invalidate(todosForScopeProvider(TodoScope.personal));
    ref.invalidate(todosForScopeProvider(TodoScope.family));
    ref.invalidate(todosProvider);
  }

  Future<void> _refreshTodos(TodoScope listScope) async {
    ref.invalidate(todosForScopeProvider(listScope));
    ref.invalidate(todosProvider);
  }

  Future<void> _showForm({Todo? todo}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => TodoFormDialog(todo: todo),
    );
    if (result == true) _invalidateAllTodoScopes();
  }

  void _showProposals() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProposalSheet(),
    );
  }

  Widget _todoListBodyForScope(TodoScope listScope) {
    final todosAsync = ref.watch(todosForScopeProvider(listScope));
    return todosAsync.when(
      data: (todos) => todos.isEmpty
          ? const EmptyState(
              icon: Icons.task_alt,
              title: 'Keine Todos',
              subtitle: 'Erstelle ein neues Todo',
            )
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(todosForScopeProvider(listScope));
                ref.invalidate(todosProvider);
              },
              child: ListView.builder(
                itemCount: todos.length,
                itemBuilder: (_, i) => _TodoItem(
                  todo: todos[i],
                  onToggleComplete: (t) => _toggleComplete(t, listScope),
                  onOpenRoot: () => context.push('/todos/${todos[i].id}'),
                  onListChanged: () => _refreshTodos(listScope),
                ),
              ),
            ),
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
    final theme = Theme.of(context);
    final showCompleted = ref.watch(_showCompletedProvider);
    final scope = ref.watch(_scopeProvider);
    final categoriesAsync = ref.watch(categoriesListProvider);
    final membersAsync = ref.watch(_membersProvider);
    final selectedCategoryId = ref.watch(_selectedCategoryIdProvider);
    final selectedViewMemberId = ref.watch(_familyViewMemberIdProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
               titleSpacing: 0,
        title: const SizedBox.shrink(),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
            tooltip: 'KI: priorisieren & kategorisieren',
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => const _TodoAiPrioritizeSheet(),
            ),
          ),
          IconButton(
            icon:
                Icon(Icons.schedule_outlined, color: theme.colorScheme.primary),
            onPressed: _showProposals,
            tooltip: 'Terminvorschläge',
          ),
          IconButton(
            icon: Icon(
              showCompleted ? Icons.visibility : Icons.visibility_off,
              color: theme.colorScheme.primary,
            ),
            onPressed: () {
              ref.read(_showCompletedProvider.notifier).state = !showCompleted;
              _invalidateAllTodoScopes();
            },
            tooltip:
                showCompleted ? 'Erledigte ausblenden' : 'Erledigte anzeigen',
          ),
        ],
      ),
      body: MainTabSwipeScope(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: TabBar(
                controller: _tabController,
                onTap: (i) {
                  final next = switch (i) {
                    0 => TodoScope.all,
                    1 => TodoScope.personal,
                    _ => TodoScope.family,
                  };
                  ref.read(_scopeProvider.notifier).state = next;
                  if (next != TodoScope.family) {
                    ref.read(_familyViewMemberIdProvider.notifier).state =
                        null;
                  }
                  ref.invalidate(todosForScopeProvider(next));
                  ref.invalidate(todosProvider);
                },
                tabs: const [
                  Tab(text: 'Alle'),
                  Tab(text: 'Meine'),
                  Tab(text: 'Familie'),
                ],
              ),
            ),
          categoriesAsync.when(
            data: (cats) {
              Future<void> openReorderSheet() async {
                final repo = ref.read(categoryRepositoryProvider);
                final local = <cat.Category>[...cats];
                await showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  isScrollControlled: true,
                  builder: (ctx) => StatefulBuilder(
                    builder: (context, setModalState) {
                      return SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kategorien anordnen',
                                style: Theme.of(ctx).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxHeight: 420),
                                child: ReorderableListView.builder(
                                  shrinkWrap: true,
                                  buildDefaultDragHandles: false,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: local.length,
                                  onReorder: (oldIndex, newIndex) async {
                                    if (newIndex > oldIndex) newIndex -= 1;
                                    setModalState(() {
                                      final item = local.removeAt(oldIndex);
                                      local.insert(newIndex, item);
                                    });
                                    try {
                                      await repo.reorderCategories(
                                          local.map((c) => c.id).toList());
                                      ref.invalidate(categoriesListProvider);
                                    } on ApiException catch (e) {
                                      if (ctx.mounted) {
                                        showAppToast(ctx,
                                            message: e.message,
                                            type: ToastType.error);
                                      }
                                    }
                                  },
                                  itemBuilder: (_, i) => ListTile(
                                    key: ValueKey('reorder_cat_${local[i].id}'),
                                    title: Text(local[i].name),
                                    trailing: ReorderableDragStartListener(
                                      index: i,
                                      child: Icon(
                                        Icons.drag_handle,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: FilledButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Fertig'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              Future<void> openManageCategories() async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CategoriesScreen(),
                  ),
                );
                ref.invalidate(categoriesListProvider);
              }

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
                                label: c.name.trim().toLowerCase() == 'familie'
                                    ? c.name
                                    : '${c.icon} ${c.name}',
                                colorHex: c.color,
                              ),
                            )
                            .toList(),
                        selectedCategoryId: selectedCategoryId,
                        onCategorySelected: (id) {
                          ref.read(_selectedCategoryIdProvider.notifier).state =
                              id;
                          _invalidateAllTodoScopes();
                        },
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Kategorien',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'manage') {
                          openManageCategories();
                        } else if (value == 'reorder') {
                          openReorderSheet();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'manage',
                          child: Text('Kategorien verwalten'),
                        ),
                        PopupMenuItem(
                          value: 'reorder',
                          child: Text('Reihenfolge ändern'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 8),
            error: (_, __) => const SizedBox(height: 8),
          ),
          if (scope == TodoScope.family)
            membersAsync.when(
              data: (members) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Alle'),
                        selected: selectedViewMemberId == null,
                        onSelected: (_) {
                          ref.read(_familyViewMemberIdProvider.notifier).state =
                              null;
                          ref.invalidate(todosForScopeProvider(TodoScope.family));
                          ref.invalidate(todosProvider);
                        },
                      ),
                      const SizedBox(width: 8),
                      ...members.map((m) {
                        final selected = selectedViewMemberId == m.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(m.name),
                            selected: selected,
                            onSelected: (_) {
                              ref
                                  .read(_familyViewMemberIdProvider.notifier)
                                  .state = selected ? null : m.id;
                              ref.invalidate(todosForScopeProvider(TodoScope.family));
                              ref.invalidate(todosProvider);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 8),
              error: (_, __) => const SizedBox(height: 8),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quickAddController,
                    decoration: const InputDecoration(
                      hintText: 'Neues Todo...',
                      prefixIcon: Icon(Icons.add_task),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _quickAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                    onPressed: _quickAdd, icon: const Icon(Icons.send)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: MainTabSwipePageEdges(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _todoListBodyForScope(TodoScope.all),
                  _todoListBodyForScope(TodoScope.personal),
                  _todoListBodyForScope(TodoScope.family),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addTodo',
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TodoAiPrioritizeSheet extends ConsumerStatefulWidget {
  const _TodoAiPrioritizeSheet();

  @override
  ConsumerState<_TodoAiPrioritizeSheet> createState() =>
      _TodoAiPrioritizeSheetState();
}

class _TodoAiPrioritizeSheetState
    extends ConsumerState<_TodoAiPrioritizeSheet> {
  bool _applying = false;

  Future<
      ({
        String summary,
        List<Map<String, dynamic>> items,
        Map<int, Todo> todoById,
        Map<int, String> categoryById
      })> _load() async {
    final todoRepo = ref.read(todoRepositoryProvider);
    final catRepo = ref.read(categoryRepositoryProvider);

    final ai = await todoRepo.prioritizeTodos();
    final items = (ai['items'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const <Map<String, dynamic>>[];
    final summary = ai['summary'] as String? ?? '';

    final cats = await catRepo.getCategories();
    final categoryById = {for (final c in cats) c.id: c.name};

    // For display purposes we need titles; fetch family+personal.
    final personal =
        await todoRepo.getTodos(scope: 'personal', completed: false);
    final family = await todoRepo.getTodos(scope: 'family', completed: false);
    final todoById = {
      for (final t in [...personal, ...family]) t.id: t
    };

    return (
      summary: summary,
      items: items,
      todoById: todoById,
      categoryById: categoryById
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Material(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: FutureBuilder(
              future: _load(),
              builder: (context, snapshot) {
                final data = snapshot.data;
                final loading =
                    snapshot.connectionState != ConnectionState.done;

                final items = data?.items ?? const <Map<String, dynamic>>[];
                final todoById = data?.todoById ?? const <int, Todo>{};
                final categoryById =
                    data?.categoryById ?? const <int, String>{};

                items.sort((a, b) {
                  final sa = (a['urgency_score'] as num?)?.toDouble() ?? 0.0;
                  final sb = (b['urgency_score'] as num?)?.toDouble() ?? 0.0;
                  return sb.compareTo(sa);
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'KI: Priorisieren & Kategorien zuweisen',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    if ((data?.summary ?? '').trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          data!.summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : snapshot.hasError
                              ? Center(child: Text('Fehler: ${snapshot.error}'))
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: items.length,
                                  itemBuilder: (_, i) {
                                    final it = items[i];
                                    final id = it['todo_id'] as int?;
                                    final todo =
                                        (id != null) ? todoById[id] : null;
                                    final title = todo?.title ??
                                        (id != null ? 'Todo #$id' : 'Todo');
                                    final pr =
                                        it['suggested_priority'] as String? ??
                                            'medium';
                                    final catId =
                                        it['suggested_category_id'] as int?;
                                    final catName = (catId != null)
                                        ? categoryById[catId]
                                        : null;
                                    final reasoning =
                                        it['reasoning'] as String? ?? '';

                                    return ListTile(
                                      title: Text(title),
                                      subtitle: reasoning.trim().isEmpty
                                          ? null
                                          : Text(reasoning),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          PriorityBadge(
                                              priority: pr, compact: true),
                                          if (catName != null)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                catName,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                  color:
                                                      theme.colorScheme.outline,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _applying ? null : () => Navigator.pop(context),
                            child: const Text('Abbrechen'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: (loading || _applying)
                                ? null
                                : () async {
                                    setState(() => _applying = true);
                                    try {
                                      final updated = await ref
                                          .read(todoRepositoryProvider)
                                          .applyTodoPriorities(items);
                                      if (context.mounted) {
                                        showAppToast(
                                          context,
                                          message:
                                              '$updated Todos aktualisiert',
                                          type: ToastType.success,
                                        );
                                        ref.invalidate(
                                            todosForScopeProvider(TodoScope.all));
                                        ref.invalidate(todosForScopeProvider(
                                            TodoScope.personal));
                                        ref.invalidate(todosForScopeProvider(
                                            TodoScope.family));
                                        ref.invalidate(todosProvider);
                                        ref.invalidate(categoriesListProvider);
                                        Navigator.pop(context);
                                      }
                                    } on ApiException catch (e) {
                                      if (context.mounted) {
                                        showAppToast(context,
                                            message: e.message,
                                            type: ToastType.error);
                                      }
                                    } finally {
                                      if (mounted)
                                        setState(() => _applying = false);
                                    }
                                  },
                            child: _applying
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('Übernehmen'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _TodoItem extends ConsumerStatefulWidget {
  final Todo todo;
  final Future<void> Function(Todo todo) onToggleComplete;
  final VoidCallback onOpenRoot;
  final Future<void> Function() onListChanged;

  const _TodoItem({
    required this.todo,
    required this.onToggleComplete,
    required this.onOpenRoot,
    required this.onListChanged,
  });

  @override
  ConsumerState<_TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends ConsumerState<_TodoItem> {
  bool _subsExpanded = false;
  bool _showInlineAdd = false;
  final _inlineController = TextEditingController();

  @override
  void dispose() {
    _inlineController.dispose();
    super.dispose();
  }

  List<Todo> get _sorted => Todo.sortedSubtodos(widget.todo.subtodos);

  Future<void> _createInlineSubtodo() async {
    final text = _inlineController.text.trim();
    if (text.isEmpty) return;
    final parent = widget.todo;
    final mid = ref.read(authStateProvider).user?.memberId;
    final data = <String, dynamic>{
      'title': text,
      'parent_id': parent.id,
      'is_personal': parent.isPersonal,
      if (!parent.isPersonal)
        'member_ids': parent.memberIds.isNotEmpty
            ? parent.memberIds
            : (mid != null ? [mid] : <int>[]),
    };
    try {
      await ref.read(todoRepositoryProvider).createTodo(data);
      _inlineController.clear();
      setState(() => _showInlineAdd = false);
      ref.invalidate(todoDetailProvider(parent.id));
      await widget.onListChanged();
      if (mounted) {
        showAppToast(
          context,
          message: 'Sub-Todo erstellt',
          type: ToastType.success,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _completeAllSubs() async {
    for (final s in _sorted.where((x) => !x.completed)) {
      try {
        final r = await ref.read(todoRepositoryProvider).completeTodo(
              s.id,
              completed: true,
            );
        if (r.parentAutoCompleted && mounted) {
          showAppToast(
            context,
            message: 'Haupt-Todo wurde automatisch erledigt',
            type: ToastType.success,
          );
        }
      } on ApiException catch (e) {
        if (mounted) {
          showAppToast(context, message: e.message, type: ToastType.error);
        }
        await widget.onListChanged();
        return;
      }
    }
    await widget.onListChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todo = widget.todo;
    final subs = _sorted;
    final completedSubs = subs.where((s) => s.completed).length;
    final totalSubs = subs.length;

    final titleStyle = todo.completed
        ? theme.textTheme.bodyLarge?.copyWith(
            decoration: TextDecoration.lineThrough,
            color: theme.colorScheme.outline,
          )
        : theme.textTheme.bodyLarge;

    Widget metaRow() {
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (todo.priority != 'none')
            PriorityBadge(priority: todo.priority, compact: true),
          if (todo.dueDate != null)
            Text(
              AppDateUtils.relativeDate(todo.dueDate!),
              style: theme.textTheme.bodySmall,
            ),
          if (todo.members.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...todo.members.take(3).map((m) {
                  final c = AppColors.memberColorFromHex(m.color);
                  return Padding(
                    padding: const EdgeInsets.only(right: 3),
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: c,
                      child: Text(
                        m.emoji ?? m.name[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.onMemberAccent(c),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
                if (todo.members.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '+${todo.members.length - 3}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          if (todo.proposalCount > 0)
            Badge(
              label: Text('${todo.proposalCount}'),
              child: const Icon(Icons.schedule, size: 16),
            ),
          if (todo.attachments.isNotEmpty)
            Icon(
              Icons.attach_file,
              size: 16,
              color: theme.colorScheme.outline,
            ),
          if (totalSubs > 0) ...[
            Text(
              '$completedSubs/$totalSubs',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            SizedBox(
              width: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: completedSubs / totalSubs,
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TodoCompletionControl(
                completed: todo.completed,
                onToggle: () => widget.onToggleComplete(todo),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onOpenRoot,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(todo.title, style: titleStyle),
                                const SizedBox(height: 4),
                                metaRow(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (totalSubs > 0)
                      IconButton(
                        icon: Icon(
                          _subsExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: theme.colorScheme.primary,
                        ),
                        tooltip: _subsExpanded
                            ? 'Sub-Todos ausblenden'
                            : 'Sub-Todos anzeigen',
                        onPressed: () => setState(() {
                          _subsExpanded = !_subsExpanded;
                          if (!_subsExpanded) {
                            _showInlineAdd = false;
                            _inlineController.clear();
                          }
                        }),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                  ],
                ),
              ),
              if (todo.eventId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Icon(
                    Icons.link,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                tooltip: 'Sub-Todo hinzufügen',
                onPressed: () => setState(() {
                  _showInlineAdd = !_showInlineAdd;
                  if (_showInlineAdd) _subsExpanded = true;
                }),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 40),
              ),
            ],
          ),
        ),
        if (_subsExpanded && subs.any((s) => !s.completed))
          Padding(
            padding: const EdgeInsets.only(left: 56, right: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _completeAllSubs,
                icon: const Icon(Icons.done_all, size: 16),
                label: const Text('Alle abhaken'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  textStyle: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
        if (_subsExpanded && subs.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 8),
            child: Column(
              children: subs.map((sub) {
                return Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    visualDensity: VisualDensity.standard,
                    contentPadding:
                        const EdgeInsets.only(left: 4, right: 4),
                    leading: TodoCompletionControl(
                      completed: sub.completed,
                      onToggle: () => widget.onToggleComplete(sub),
                      iconSize: 26,
                    ),
                    title: Text(
                      sub.title,
                      style: sub.completed
                          ? theme.textTheme.bodySmall?.copyWith(
                              decoration: TextDecoration.lineThrough,
                            )
                          : theme.textTheme.bodySmall,
                    ),
                    subtitle: sub.dueDate != null
                        ? Text(
                            AppDateUtils.relativeDate(sub.dueDate!),
                            style: theme.textTheme.bodySmall,
                          )
                        : (sub.priority != 'none'
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: PriorityBadge(
                                  priority: sub.priority,
                                  compact: true,
                                ),
                              )
                            : null),
                    trailing: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: theme.colorScheme.outline,
                    ),
                    onTap: () => context.push('/todos/${sub.id}'),
                  ),
                );
              }).toList(),
            ),
          ),
        if (_showInlineAdd)
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inlineController,
                    decoration: const InputDecoration(
                      hintText: 'Sub-Todo …',
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _createInlineSubtodo(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _createInlineSubtodo,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _inlineController.clear();
                    setState(() => _showInlineAdd = false);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class AppDateUtils {
  static String relativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (diff == 0) return 'Heute';
    if (diff == 1) return 'Morgen';
    if (diff == -1) return 'Gestern';
    return '${date.day}.${date.month}.${date.year}';
  }
}

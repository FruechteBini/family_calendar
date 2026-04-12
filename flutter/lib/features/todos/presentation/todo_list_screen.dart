import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart' as cat;
import '../../categories/presentation/categories_screen.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/family_member.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/category_accent_chips.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';
import 'todo_form_dialog.dart';
import 'proposal_sheet.dart';

final _showCompletedProvider = StateProvider<bool>((ref) => false);

enum TodoScope { all, personal, family }

final _scopeProvider = StateProvider<TodoScope>((ref) => TodoScope.all);
final _selectedCategoryIdProvider = StateProvider<int?>((ref) => null);
final _familyViewMemberIdProvider = StateProvider<int?>((ref) => null);

final _categoriesProvider = FutureProvider<List<cat.Category>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final _membersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  return ref.watch(memberRepositoryProvider).getMembers();
});

final todosProvider = FutureProvider<List<Todo>>((ref) {
  final scope = ref.watch(_scopeProvider);
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

class TodoListScreen extends ConsumerStatefulWidget {
  const TodoListScreen({super.key});

  @override
  ConsumerState<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends ConsumerState<TodoListScreen> {
  final _quickAddController = TextEditingController();

  @override
  void dispose() {
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
      ref.invalidate(todosProvider);
      if (mounted)
        showAppToast(context,
            message: 'Todo erstellt', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted)
        showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _toggleComplete(Todo todo) async {
    try {
      await ref.read(todoRepositoryProvider).completeTodo(
            todo.id,
            completed: !todo.completed,
          );
      ref.invalidate(todosProvider);
    } on ApiException catch (e) {
      if (mounted)
        showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _showForm({Todo? todo}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => TodoFormDialog(todo: todo),
    );
    if (result == true) ref.invalidate(todosProvider);
  }

  void _showProposals() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const ProposalSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todosAsync = ref.watch(todosProvider);
    final showCompleted = ref.watch(_showCompletedProvider);
    final scope = ref.watch(_scopeProvider);
    final categoriesAsync = ref.watch(_categoriesProvider);
    final membersAsync = ref.watch(_membersProvider);
    final selectedCategoryId = ref.watch(_selectedCategoryIdProvider);
    final selectedViewMemberId = ref.watch(_familyViewMemberIdProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Todos',
          style: theme.textTheme.titleLarge
              ?.copyWith(color: theme.colorScheme.primary),
        ),
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
            onPressed: () => ref.read(_showCompletedProvider.notifier).state =
                !showCompleted,
            tooltip:
                showCompleted ? 'Erledigte ausblenden' : 'Erledigte anzeigen',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DefaultTabController(
              length: 3,
              initialIndex: switch (scope) {
                TodoScope.all => 0,
                TodoScope.personal => 1,
                TodoScope.family => 2,
              },
              child: Builder(
                builder: (context) {
                  return TabBar(
                    onTap: (i) {
                      final next = switch (i) {
                        0 => TodoScope.all,
                        1 => TodoScope.personal,
                        _ => TodoScope.family,
                      };
                      ref.read(_scopeProvider.notifier).state = next;
                      // reset family view filter when leaving family tab
                      if (next != TodoScope.family) {
                        ref.read(_familyViewMemberIdProvider.notifier).state =
                            null;
                      }
                      ref.invalidate(todosProvider);
                    },
                    tabs: const [
                      Tab(text: 'Alle'),
                      Tab(text: 'Meine'),
                      Tab(text: 'Familie'),
                    ],
                  );
                },
              ),
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
                                      ref.invalidate(_categoriesProvider);
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
                ref.invalidate(_categoriesProvider);
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
                                label: '${c.icon} ${c.name}',
                                colorHex: c.color,
                              ),
                            )
                            .toList(),
                        selectedCategoryId: selectedCategoryId,
                        onCategorySelected: (id) {
                          ref.read(_selectedCategoryIdProvider.notifier).state =
                              id;
                          ref.invalidate(todosProvider);
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Kategorien verwalten',
                      onPressed: openManageCategories,
                      icon: const Icon(Icons.add),
                    ),
                    IconButton(
                      tooltip: 'Kategorien anordnen',
                      onPressed: openReorderSheet,
                      icon: const Icon(Icons.drag_handle),
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
            child: todosAsync.when(
              data: (todos) => todos.isEmpty
                  ? const EmptyState(
                      icon: Icons.task_alt,
                      title: 'Keine Todos',
                      subtitle: 'Erstelle ein neues Todo')
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(todosProvider),
                      child: ListView.builder(
                        itemCount: todos.length,
                        itemBuilder: (_, i) => _TodoItem(
                          todo: todos[i],
                          onToggle: () => _toggleComplete(todos[i]),
                          onTap: () => _showForm(todo: todos[i]),
                          onSubtodos: todos[i].subtodos,
                          toggleSubtodo: _toggleComplete,
                        ),
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                  icon: Icons.error_outline,
                  title: 'Fehler',
                  subtitle: e.toString()),
            ),
          ),
        ],
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
                                        ref.invalidate(todosProvider);
                                        ref.invalidate(_categoriesProvider);
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

class _TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final List<Todo> onSubtodos;
  final ValueChanged<Todo> toggleSubtodo;

  const _TodoItem({
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onSubtodos,
    required this.toggleSubtodo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ListTile(
          leading: Checkbox(
            value: todo.completed,
            onChanged: (_) => onToggle(),
          ),
          title: Text(
            todo.title,
            style: todo.completed
                ? theme.textTheme.bodyLarge?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.outline)
                : theme.textTheme.bodyLarge,
          ),
          subtitle: Row(
            children: [
              if (todo.priority != 'none') ...[
                PriorityBadge(priority: todo.priority, compact: true),
                const SizedBox(width: 8),
              ],
              if (todo.dueDate != null)
                Text(
                  AppDateUtils.relativeDate(todo.dueDate!),
                  style: theme.textTheme.bodySmall,
                ),
              if (todo.members.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: todo.members
                        .take(2)
                        .map((m) => Text(m.emoji ?? m.name[0],
                            style: const TextStyle(fontSize: 12)))
                        .toList(),
                  ),
                ),
              if (todo.proposalCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Badge(
                      label: Text('${todo.proposalCount}'),
                      child: const Icon(Icons.schedule, size: 16)),
                ),
            ],
          ),
          trailing:
              todo.eventId != null ? const Icon(Icons.link, size: 16) : null,
          onTap: onTap,
        ),
        if (onSubtodos.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: Column(
              children: onSubtodos.map((sub) {
                return ListTile(
                  dense: true,
                  leading: Checkbox(
                    value: sub.completed,
                    onChanged: (_) => toggleSubtodo(sub),
                  ),
                  title: Text(
                    sub.title,
                    style: sub.completed
                        ? theme.textTheme.bodySmall
                            ?.copyWith(decoration: TextDecoration.lineThrough)
                        : theme.textTheme.bodySmall,
                  ),
                );
              }).toList(),
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

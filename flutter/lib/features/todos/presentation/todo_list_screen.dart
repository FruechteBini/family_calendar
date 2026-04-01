import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';
import 'todo_form_dialog.dart';
import 'proposal_sheet.dart';

final _filterPriorityProvider = StateProvider<String?>((ref) => null);
final _filterMemberProvider = StateProvider<int?>((ref) => null);
final _showCompletedProvider = StateProvider<bool>((ref) => false);

final todosProvider = FutureProvider<List<Todo>>((ref) {
  final priority = ref.watch(_filterPriorityProvider);
  final memberId = ref.watch(_filterMemberProvider);
  final showCompleted = ref.watch(_showCompletedProvider);
  return ref.watch(todoRepositoryProvider).getTodos(
    priority: priority,
    memberId: memberId,
    completed: showCompleted ? null : false,
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
      await ref.read(todoRepositoryProvider).createTodo({'title': text});
      _quickAddController.clear();
      ref.invalidate(todosProvider);
      if (mounted) showAppToast(context, message: 'Todo erstellt', type: ToastType.success);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
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
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aufgaben'),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule_outlined),
            onPressed: _showProposals,
            tooltip: 'Terminvorschlaege',
          ),
          IconButton(
            icon: Icon(showCompleted ? Icons.visibility : Icons.visibility_off),
            onPressed: () => ref.read(_showCompletedProvider.notifier).state = !showCompleted,
            tooltip: showCompleted ? 'Erledigte ausblenden' : 'Erledigte anzeigen',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => ref.read(_filterPriorityProvider.notifier).state = v == 'all' ? null : v,
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('Alle Prioritaeten')),
              const PopupMenuItem(value: 'high', child: PriorityBadge(priority: 'high')),
              const PopupMenuItem(value: 'medium', child: PriorityBadge(priority: 'medium')),
              const PopupMenuItem(value: 'low', child: PriorityBadge(priority: 'low')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quickAddController,
                    decoration: const InputDecoration(
                      hintText: 'Neue Aufgabe...',
                      prefixIcon: Icon(Icons.add_task),
                      isDense: true,
                    ),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _quickAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _quickAdd, icon: const Icon(Icons.send)),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: todosAsync.when(
              data: (todos) => todos.isEmpty
                  ? const EmptyState(icon: Icons.task_alt, title: 'Keine Aufgaben', subtitle: 'Erstelle eine neue Aufgabe')
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
              error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Fehler', subtitle: e.toString()),
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
                ? theme.textTheme.bodyLarge?.copyWith(decoration: TextDecoration.lineThrough, color: theme.colorScheme.outline)
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
                    children: todo.members.take(2).map((m) => Text(m.emoji ?? m.name[0], style: const TextStyle(fontSize: 12))).toList(),
                  ),
                ),
              if (todo.proposalCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Badge(label: Text('${todo.proposalCount}'), child: const Icon(Icons.schedule, size: 16)),
                ),
            ],
          ),
          trailing: todo.eventId != null ? const Icon(Icons.link, size: 16) : null,
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
                        ? theme.textTheme.bodySmall?.copyWith(decoration: TextDecoration.lineThrough)
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

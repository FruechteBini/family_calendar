import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/preferences/todo_preferences.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/member_chip.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/todo_complete_checkbox.dart';
import '../../../shared/widgets/toast.dart';
import '../../members/domain/family_member.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../domain/todo_attachment.dart';
import 'todo_attachment_helpers.dart';
import 'todo_form_dialog.dart';

final todoDetailProvider = FutureProvider.family<Todo, int>((ref, id) async {
  return ref.watch(todoRepositoryProvider).getTodo(id);
});

class TodoDetailScreen extends ConsumerStatefulWidget {
  final int todoId;

  const TodoDetailScreen({super.key, required this.todoId});

  @override
  ConsumerState<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends ConsumerState<TodoDetailScreen> {
  final _inlineSubController = TextEditingController();
  bool _showInlineAdd = false;

  @override
  void dispose() {
    _inlineSubController.dispose();
    super.dispose();
  }

  Future<void> _refreshAfterChange() async {
    ref.invalidate(todoDetailProvider(widget.todoId));
    ref.read(todoListRefreshTriggerProvider.notifier).state++;
  }

  Future<void> _edit(Todo todo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => TodoFormDialog(todo: todo),
    );
    if (result != true || !mounted) return;
    try {
      await ref.read(todoRepositoryProvider).getTodo(widget.todoId);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        notifyDataMutated(ref);
        if (mounted) context.pop();
        return;
      }
    }
    await _refreshAfterChange();
  }

  Future<void> _toggleComplete(Todo todo) async {
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
      await _refreshAfterChange();
      if (mounted && updated.parentAutoCompleted) {
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
    }
  }

  Future<void> _createInlineSubtodo(Todo parent) async {
    final text = _inlineSubController.text.trim();
    if (text.isEmpty) return;
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
      _inlineSubController.clear();
      setState(() => _showInlineAdd = false);
      await _refreshAfterChange();
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

  Future<void> _onReorderSubs(Todo parent, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = [...Todo.sortedSubtodos(parent.subtodos)];
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    final ids = list.map((e) => e.id).toList();
    try {
      await ref
          .read(todoRepositoryProvider)
          .reorderSubtodos(parent.id, ids);
      await _refreshAfterChange();
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _completeAllSubs(List<Todo> subs) async {
    for (final s in subs.where((x) => !x.completed)) {
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
        await _refreshAfterChange();
        return;
      }
    }
    await _refreshAfterChange();
  }

  void _openImageAttachmentViewer(
    TodoAttachment a,
    Map<String, String>? headers,
  ) {
    final url = todoAttachmentFullUrl(ref, a);
    if (url.isEmpty) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (ctx) => _TodoImageViewerScreen(
          imageUrl: url,
          httpHeaders: headers,
          title: a.filename,
        ),
      ),
    );
  }

  Future<void> _onAttachmentTap(
    TodoAttachment a,
    Map<String, String>? headers,
  ) async {
    if (todoAttachmentIsImage(a)) {
      _openImageAttachmentViewer(a, headers);
      return;
    }
    await _openAttachmentUrl(a);
  }

  Future<void> _openAttachmentUrl(TodoAttachment a) async {
    final url = todoAttachmentFullUrl(ref, a);
    if (url.isEmpty) return;

    // Browser / external app requests have no JWT; download with Dio then open locally.
    if (kIsWeb) {
      final u = Uri.tryParse(url);
      if (u != null && await canLaunchUrl(u)) {
        await launchUrl(
          u,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: '_blank',
        );
      } else if (mounted) {
        showAppToast(
          context,
          message: 'Anhang konnte nicht geöffnet werden',
          type: ToastType.error,
        );
      }
      return;
    }

    try {
      final dio = ref.read(dioProvider);
      final tempDir = await getTemporaryDirectory();
      var safeName = p
          .basename(a.filename.isNotEmpty ? a.filename : 'file')
          .replaceAll(RegExp(r'[^\w.\-]'), '_');
      if (safeName.isEmpty) safeName = 'file_${a.id}';
      final localPath = p.join(
        tempDir.path,
        'todo_att_${widget.todoId}_${a.id}_$safeName',
      );
      await dio.download(url, localPath);
      final result = await OpenFile.open(localPath);
      if (result.type != ResultType.done && mounted) {
        showAppToast(
          context,
          message: result.message.isNotEmpty
              ? result.message
              : 'Anhang konnte nicht geöffnet werden',
          type: ToastType.error,
        );
      }
    } on DioException catch (e) {
      if (!mounted) return;
      showAppToast(
        context,
        message: ApiException.fromDioError(e).message,
        type: ToastType.error,
      );
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          message: e.toString(),
          type: ToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.todoId <= 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Todo')),
        body: const EmptyState(
          icon: Icons.task_alt,
          title: 'Ungültiges Todo',
          subtitle: 'Dieser Eintrag existiert nicht.',
        ),
      );
    }

    final theme = Theme.of(context);
    final todoAsync = ref.watch(todoDetailProvider(widget.todoId));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: todoAsync.maybeWhen(
          data: (t) => Text(
            t.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          orElse: () => const Text('Todo'),
        ),
        actions: [
          todoAsync.maybeWhen(
            data: (t) => IconButton(
              tooltip: 'Bearbeiten',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(t),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: todoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Todo konnte nicht geladen werden',
          subtitle: err is ApiException ? err.message : err.toString(),
        ),
        data: (todo) {
          final subs = Todo.sortedSubtodos(todo.subtodos);
          final completedSubs = subs.where((s) => s.completed).length;
          final headers = todoImageRequestHeaders(ref);

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(todoDetailProvider(widget.todoId)),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (todo.parentId != null) ...[
                  OutlinedButton.icon(
                    onPressed: () =>
                        context.pushReplacement('/todos/${todo.parentId}'),
                    icon: const Icon(Icons.subdirectory_arrow_left, size: 18),
                    label: const Text('Zum Haupt-Todo'),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TodoCompleteCheckbox(
                      value: todo.completed,
                      onChanged: (_) => _toggleComplete(todo),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          todo.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: todo.completed
                                ? TextDecoration.lineThrough
                                : null,
                            color: todo.completed
                                ? theme.colorScheme.outline
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (todo.description != null &&
                    todo.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.notes_outlined,
                    label: 'Beschreibung',
                    child: SelectableText(
                      todo.description!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (todo.categoryName != null &&
                    todo.categoryName!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailSection(
                    icon: Icons.folder_outlined,
                    label: 'Kategorie',
                    child: Text(
                      todo.categoryName!,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (todo.priority != 'none') ...[
                  const SizedBox(height: 12),
                  _DetailSection(
                    icon: Icons.flag_outlined,
                    label: 'Priorität',
                    child: PriorityBadge(priority: todo.priority),
                  ),
                ],
                if (todo.dueDate != null) ...[
                  const SizedBox(height: 12),
                  _DetailSection(
                    icon: Icons.event_outlined,
                    label: 'Fällig',
                    child: Text(
                      AppDateUtils.relativeDate(todo.dueDate!),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
                if (todo.members.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailSection(
                    icon: Icons.people_outline,
                    label: 'Zugewiesen',
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: todo.members
                          .map(
                            (m) => MemberChip(
                              member: FamilyMember(
                                id: m.id,
                                name: m.name,
                                emoji: m.emoji,
                                color: m.color,
                              ),
                              selected: true,
                              mode: MemberChipMode.display,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
                if (todo.eventId != null) ...[
                  const SizedBox(height: 12),
                  _DetailSection(
                    icon: Icons.event_available_outlined,
                    label: 'Kalendertermin',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final id = todo.linkedEvent?.id ?? todo.eventId!;
                          context.push('/events/$id');
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todo.linkedEvent?.title ??
                                          'Mit Termin verknüpft',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (todo.linkedEvent != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        todo.linkedEvent!.allDay
                                            ? AppDateUtils.formatDate(
                                                todo.linkedEvent!.start,
                                              )
                                            : '${AppDateUtils.formatDate(todo.linkedEvent!.start)} · ${AppDateUtils.formatTime(todo.linkedEvent!.start)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (todo.attachments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DetailSection(
                    icon: Icons.attach_file,
                    label: 'Anhänge',
                    child: SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: todo.attachments.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, i) {
                          final a = todo.attachments[i];
                          final url = todoAttachmentFullUrl(ref, a);
                          final isImg = todoAttachmentIsImage(a);
                          final isVid = todoAttachmentIsVideo(a);
                          return InkWell(
                            onTap: () => _onAttachmentTap(a, headers),
                            borderRadius: BorderRadius.circular(8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: isImg
                                    ? CachedNetworkImage(
                                        imageUrl: url,
                                        fit: BoxFit.cover,
                                        httpHeaders: headers,
                                        errorWidget: (_, __, ___) =>
                                            _AttachmentFallback(
                                          filename: a.filename,
                                          isVideo: isVid,
                                        ),
                                      )
                                    : _AttachmentFallback(
                                        filename: a.filename,
                                        isVideo: isVid,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                if (todo.parentId == null) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Sub-Todos',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),
                      if (subs.isNotEmpty)
                        Text(
                          '$completedSubs/${subs.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      IconButton(
                        tooltip: 'Sub-Todo hinzufügen',
                        icon: const Icon(Icons.add),
                        onPressed: () =>
                            setState(() => _showInlineAdd = !_showInlineAdd),
                      ),
                    ],
                  ),
                  if (subs.any((s) => !s.completed))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => _completeAllSubs(subs),
                        icon: const Icon(Icons.done_all, size: 18),
                        label: const Text('Alle abhaken'),
                      ),
                    ),
                  if (subs.isNotEmpty)
                    SizedBox(
                      height: math.max(72.0 * subs.length, 72),
                      child: ReorderableListView.builder(
                        buildDefaultDragHandles: false,
                        itemCount: subs.length,
                        onReorder: (o, n) => _onReorderSubs(todo, o, n),
                        itemBuilder: (context, index) {
                          final sub = subs[index];
                          return ReorderableDragStartListener(
                            index: index,
                            key: ValueKey('detail-sub-${sub.id}'),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: TodoCompleteCheckbox(
                                  value: sub.completed,
                                  onChanged: (_) => _toggleComplete(sub),
                                ),
                                title: Text(
                                  sub.title,
                                  style: sub.completed
                                      ? theme.textTheme.bodyMedium?.copyWith(
                                          decoration:
                                              TextDecoration.lineThrough,
                                          color: theme.colorScheme.outline,
                                        )
                                      : theme.textTheme.bodyMedium,
                                ),
                                subtitle: sub.dueDate != null
                                    ? Text(
                                        AppDateUtils.relativeDate(sub.dueDate!),
                                        style: theme.textTheme.bodySmall,
                                      )
                                    : null,
                                trailing: Icon(
                                  Icons.drag_handle,
                                  color: theme.colorScheme.outline,
                                ),
                                onTap: () => context.push('/todos/${sub.id}'),
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Noch keine Sub-Todos.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  if (_showInlineAdd)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _inlineSubController,
                            decoration: const InputDecoration(
                              hintText: 'Neues Sub-Todo …',
                              isDense: true,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _createInlineSubtodo(todo),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () => _createInlineSubtodo(todo),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _inlineSubController.clear();
                            setState(() => _showInlineAdd = false);
                          },
                        ),
                      ],
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TodoImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final Map<String, String>? httpHeaders;
  final String title;

  const _TodoImageViewerScreen({
    required this.imageUrl,
    required this.httpHeaders,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: InteractiveViewer(
        minScale: 0.5,
        maxScale: 4,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            httpHeaders: httpHeaders,
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
            errorWidget: (_, __, ___) => const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white54,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Bild konnte nicht geladen werden',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentFallback extends StatelessWidget {
  final String filename;
  final bool isVideo;

  const _AttachmentFallback({
    required this.filename,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isVideo ? Icons.videocam_outlined : Icons.insert_drive_file,
                size: 28,
              ),
              Text(
                filename,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/family_member.dart';
import '../../todos/data/todo_repository.dart';
import '../../todos/domain/todo.dart';
import '../../../core/sync/sync_service.dart';
import '../../../shared/widgets/category_picker.dart';
import '../../../shared/widgets/member_chip.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/utils/app_time_picker.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/preferences/calendar_defaults.dart';
import '../../notifications/presentation/widgets/notification_level_picker.dart';

/// Returned from [EventFormDialog] when the user saves or deletes (not on cancel).
enum EventFormDialogOutcome { saved, deleted }

final _categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final _membersProvider = FutureProvider<List<FamilyMember>>((ref) {
  return ref.watch(memberRepositoryProvider).getMembers();
});

final _todosForEventLinkProvider = FutureProvider.autoDispose<List<Todo>>((ref) {
  return ref.watch(todoRepositoryProvider).getTodos(scope: 'all', completed: false);
});

class EventFormDialog extends ConsumerStatefulWidget {
  final Event? event;
  final DateTime initialDate;

  const EventFormDialog({super.key, this.event, required this.initialDate});

  @override
  ConsumerState<EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends ConsumerState<EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  bool _allDay = false;
  int? _categoryId;
  Set<int> _memberIds = {};
  int? _notificationLevelId;
  bool _saving = false;
  final _extraTodoTitleController = TextEditingController();
  final List<String> _pendingNewTodoTitles = [];
  final Set<int> _unlinkTodoIds = {};
  final Set<int> _selectedExistingTodoIds = {};

  bool get _isEditing => widget.event != null;

  Set<int> get _activeLinkedTodoIds => {
        for (final t in widget.event?.linkedTodos ?? const <EventLinkedTodo>[])
          if (!_unlinkTodoIds.contains(t.id)) t.id,
      };

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _startDate = e?.startTime ?? widget.initialDate;
    _startTime = e != null ? TimeOfDay.fromDateTime(e.startTime) : const TimeOfDay(hour: 10, minute: 0);
    _endDate = e?.endTime ?? widget.initialDate;
    _endTime = e != null ? TimeOfDay.fromDateTime(e.endTime) : const TimeOfDay(hour: 11, minute: 0);
    _allDay = e?.allDay ?? false;
    _categoryId = e?.categoryId;
    _memberIds = (e?.memberIds ?? []).toSet();
    _notificationLevelId = (e?.notificationLevelId);
    if (e == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(_applyDefaultCategoryIfEmpty);
      });
    }
  }

  bool _categoryIdExistsInList(int? id, List<Category> cats) {
    if (id == null) return false;
    return cats.any((c) => c.id == id);
  }

  /// Sets [_categoryId] when still null (new event). Uses settings + single-category fallback.
  void _applyDefaultCategoryIfEmpty() {
    if (_isEditing || _categoryId != null) return;
    final myId = ref.read(authStateProvider).user?.memberId;
    final defs = ref.read(calendarDefaultsProvider).valueOrNull;
    final cats = ref.read(_categoriesProvider).valueOrNull ?? [];
    int? pickFamily() {
      final f = defs?.familyDefaultCalendarCategoryId;
      if (_categoryIdExistsInList(f, cats)) return f;
      if (cats.length == 1) return cats.first.id;
      return null;
    }

    int? pickPersonal() {
      final p = defs?.personalCalendarCategoryId;
      if (_categoryIdExistsInList(p, cats)) return p;
      return pickFamily();
    }

    if (myId == null) {
      _categoryId = pickFamily();
      return;
    }
    final personalOnly = _memberIds.length == 1 && _memberIds.contains(myId);
    _categoryId = personalOnly ? pickPersonal() : pickFamily();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _extraTodoTitleController.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Future<void> _applyTodoLinks(int eventId) async {
    final todoRepo = ref.read(todoRepositoryProvider);
    if (_isEditing) {
      for (final id in _unlinkTodoIds) {
        await todoRepo.linkTodoToEvent(id, null);
      }
    }
    for (final id in _selectedExistingTodoIds) {
      await todoRepo.linkTodoToEvent(id, eventId);
    }
    for (final title in _pendingNewTodoTitles) {
      final t = title.trim();
      if (t.isEmpty) continue;
      await todoRepo.createTodo({
        'title': t,
        'is_personal': false,
        'member_ids': _memberIds.toList(),
        'event_id': eventId,
        'priority': 'low',
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'start': _allDay
            ? AppDateUtils.startOfDay(_startDate).toIso8601String()
            : _combine(_startDate, _startTime).toIso8601String(),
        'end': _allDay
            ? AppDateUtils.endOfDay(_endDate).toIso8601String()
            : _combine(_endDate, _endTime).toIso8601String(),
        'all_day': _allDay,
        'category_id': _categoryId,
        'member_ids': _memberIds.toList(),
        'notification_level_id': _notificationLevelId,
      };
      final repo = ref.read(eventRepositoryProvider);
      final Event saved;
      if (_isEditing) {
        saved = await repo.updateEvent(widget.event!.id, data);
      } else {
        saved = await repo.createEvent(data);
      }
      try {
        await _applyTodoLinks(saved.id);
      } on ApiException catch (e) {
        if (mounted) {
          showAppToast(
            context,
            message: 'Termin gespeichert, Todos: ${e.message}',
            type: ToastType.error,
          );
        }
      }
      ref.read(syncTickProvider.notifier).state++;
      if (mounted) Navigator.of(context).pop(EventFormDialogOutcome.saved);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Termin löschen?'),
        content: Text('Soll "${widget.event!.title}" wirklich gelöscht werden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(widget.event!.id);
      ref.read(syncTickProvider.notifier).state++;
      if (mounted) Navigator.of(context).pop(EventFormDialogOutcome.deleted);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Category>>>(_categoriesProvider, (_, next) {
      if (next.hasValue && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_applyDefaultCategoryIfEmpty);
        });
      }
    });
    ref.listen<AsyncValue<CalendarDefaultsPreferences>>(
        calendarDefaultsProvider, (_, next) {
      if (next.hasValue && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(_applyDefaultCategoryIfEmpty);
        });
      }
    });

    final categories = ref.watch(_categoriesProvider).valueOrNull ?? [];
    final members = ref.watch(_membersProvider).valueOrNull ?? [];

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isEditing ? 'Termin bearbeiten' : 'Neuer Termin',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (_isEditing)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: _delete,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Titel', prefixIcon: Icon(Icons.title)),
                    autofocus: !_isEditing,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Titel erforderlich' : null,
                  ),
                  const SizedBox(height: 12),
                  LabeledMultilineTextField(
                    label: 'Beschreibung',
                    controller: _descriptionController,
                    hintText:
                        'Optional — Ort, Agenda, Links oder weitere Details …',
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Ganztägig'),
                    value: _allDay,
                    onChanged: (v) => setState(() => _allDay = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  _buildDateTimeRow('Beginn', _startDate, _startTime, (d) => setState(() => _startDate = d), (t) => setState(() => _startTime = t)),
                  const SizedBox(height: 8),
                  _buildDateTimeRow('Ende', _endDate, _endTime, (d) => setState(() => _endDate = d), (t) => setState(() => _endTime = t)),
                  const SizedBox(height: 12),
                  CategoryPicker(
                    categories: categories,
                    selectedId: _categoryId,
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  NotificationLevelPicker(
                    value: _notificationLevelId,
                    onChanged: (v) => setState(() => _notificationLevelId = v),
                  ),
                  const SizedBox(height: 12),
                  Text('Mitglieder', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  MemberChipRow(
                    members: members,
                    selectedIds: _memberIds,
                    onToggle: (id) => setState(() {
                      if (_memberIds.contains(id)) {
                        _memberIds.remove(id);
                      } else {
                        _memberIds.add(id);
                      }
                      _applyDefaultCategoryIfEmpty();
                    }),
                  ),
                  const SizedBox(height: 12),
                  _buildTodosExpansion(context),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Abbrechen'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_isEditing ? 'Speichern' : 'Erstellen'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _addPendingTodoLine() {
    final t = _extraTodoTitleController.text.trim();
    if (t.isEmpty) return;
    setState(() {
      _pendingNewTodoTitles.add(t);
      _extraTodoTitleController.clear();
    });
  }

  Widget _buildTodosExpansion(BuildContext context) {
    final theme = Theme.of(context);
    final todosAsync = ref.watch(_todosForEventLinkProvider);
    final eventId = widget.event?.id;
    final visibleLinked =
        widget.event?.linkedTodos.where((t) => !_unlinkTodoIds.contains(t.id)).toList() ?? [];

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Row(
        children: [
          Icon(Icons.task_alt, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Todos verknüpfen', style: theme.textTheme.titleSmall),
        ],
      ),
      subtitle: Text(
        'Fälligkeit und Push-Stufe kommen vom Termin.',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      children: [
        if (visibleLinked.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Verknüpft', style: theme.textTheme.labelMedium),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in visibleLinked)
                InputChip(
                  label: Text(
                    t.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: t.completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  onDeleted: () => setState(() => _unlinkTodoIds.add(t.id)),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Bestehende hinzufügen', style: theme.textTheme.labelMedium),
        ),
        const SizedBox(height: 4),
        todosAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (e, _) => Text('$e', style: TextStyle(color: theme.colorScheme.error)),
          data: (all) {
            final linked = _activeLinkedTodoIds;
            final available = all.where((t) {
              if (t.completed || t.parentId != null) return false;
              if (t.eventId != null && t.eventId != eventId) return false;
              if (linked.contains(t.id)) return false;
              return true;
            }).toList();
            if (available.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Keine weiteren offenen Todos.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                itemCount: available.length,
                itemBuilder: (context, i) {
                  final t = available[i];
                  final checked = _selectedExistingTodoIds.contains(t.id);
                  return CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: checked,
                    title: Text(t.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _unlinkTodoIds.remove(t.id);
                          _selectedExistingTodoIds.add(t.id);
                        } else {
                          _selectedExistingTodoIds.remove(t.id);
                        }
                      });
                    },
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Neues Todo', style: theme.textTheme.labelMedium),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _extraTodoTitleController,
                decoration: const InputDecoration(
                  hintText: 'Titel',
                  isDense: true,
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addPendingTodoLine(),
              ),
            ),
            IconButton(
              tooltip: 'Zur Liste',
              onPressed: _addPendingTodoLine,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
        if (_pendingNewTodoTitles.isNotEmpty) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in _pendingNewTodoTitles)
                InputChip(
                  label: Text(t, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onDeleted: () => setState(() => _pendingNewTodoTitles.remove(t)),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDateTimeRow(
    String label,
    DateTime date,
    TimeOfDay time,
    ValueChanged<DateTime> onDateChanged,
    ValueChanged<TimeOfDay> onTimeChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                locale: const Locale('de'),
              );
              if (picked != null) onDateChanged(picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.calendar_today, size: 18)),
              child: Text(AppDateUtils.formatDate(date)),
            ),
          ),
        ),
        if (!_allDay) ...[
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: InkWell(
              onTap: () async {
                final picked = await showAppTimePicker(context, initialTime: time);
                if (picked != null) onTimeChanged(picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.access_time, size: 18)),
                child: Text('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import '../domain/event_recurrence.dart';
import '../../categories/categories_providers.dart';
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
  List<EventRecurrenceRule> _recurrenceRules = [];
  String? _eventColorHex;

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
    _eventColorHex = e?.color;
    if (e != null && e.recurrenceRules.isNotEmpty) {
      _recurrenceRules = List.of(e.recurrenceRules);
    }
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
    final cats = ref.read(categoriesListProvider).valueOrNull ?? [];
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

  void _stripPersonalCategoryIfNotSolo(List<Category> cats) {
    final myId = ref.read(authStateProvider).user?.memberId;
    final solo = myId != null &&
        _memberIds.length == 1 &&
        _memberIds.contains(myId);
    if (solo) return;
    final id = _categoryId;
    if (id == null) return;
    for (final c in cats) {
      if (c.id == id && c.isPersonal) {
        _categoryId = null;
        return;
      }
    }
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
      final allCats = ref.read(categoriesListProvider).valueOrNull ?? [];
      final myMid = ref.read(authStateProvider).user?.memberId;
      final soloEv = myMid != null &&
          _memberIds.length == 1 &&
          _memberIds.contains(myMid);
      final allowedCats = soloEv
          ? allCats
          : allCats.where((c) => !c.isPersonal).toList();
      int? safeCategoryId = _categoryId;
      if (safeCategoryId != null &&
          !allowedCats.any((c) => c.id == safeCategoryId)) {
        safeCategoryId = null;
      }

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
        'category_id': safeCategoryId,
        'member_ids': _memberIds.toList(),
        'notification_level_id': _notificationLevelId,
        'color': _eventColorHex,
      };
      if (_recurrenceRules.isNotEmpty) {
        data['recurrence_rules'] =
            _recurrenceRules.map((r) => r.toJson()).toList();
      } else if (_isEditing && (widget.event!.recurrenceRules.isNotEmpty)) {
        data['recurrence_rules'] = <Map<String, dynamic>>[];
      }
      if (_isEditing &&
          widget.event!.isRecurringOccurrence &&
          widget.event!.recurrenceAnchorStart != null) {
        data['recurrence_anchor_start'] =
            widget.event!.recurrenceAnchorStart!.toUtc().toIso8601String();
      }
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
    final isSeries = widget.event!.recurrenceRules.isNotEmpty;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Termin löschen?'),
        content: Text(
          isSeries
              ? 'Die gesamte Serie „${widget.event!.title}“ wird gelöscht (alle Wiederholungen).'
              : 'Soll „${widget.event!.title}“ wirklich gelöscht werden?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(widget.event!.id);
      notifyDataMutated(ref);
      if (mounted) Navigator.of(context).pop(EventFormDialogOutcome.deleted);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<Category>>>(categoriesListProvider, (_, next) {
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

    final categories = ref.watch(categoriesListProvider).valueOrNull ?? [];
    final members = ref.watch(_membersProvider).valueOrNull ?? [];
    final myMemberId = ref.watch(authStateProvider).user?.memberId;
    final soloPersonalEvent = myMemberId != null &&
        _memberIds.length == 1 &&
        _memberIds.contains(myMemberId);
    final categoriesForPicker = soloPersonalEvent
        ? categories
        : categories.where((c) => !c.isPersonal).toList();
    final categoryPickerValue = _categoryId != null &&
            categoriesForPicker.any((c) => c.id == _categoryId)
        ? _categoryId
        : null;

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
                          tooltip: 'Löschen',
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          iconSize: 28,
                          style: IconButton.styleFrom(
                            minimumSize: const Size(52, 52),
                            padding: const EdgeInsets.all(14),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
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
                  _buildRecurrenceSection(context),
                  const SizedBox(height: 12),
                  CategoryPicker(
                    categories: categoriesForPicker,
                    selectedId: categoryPickerValue,
                    onChanged: (v) => setState(() => _categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  _buildEventColorSection(context, categories),
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
                      _stripPersonalCategoryIfNotSolo(
                        ref.read(categoriesListProvider).valueOrNull ?? [],
                      );
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

  static const _weekdayShort = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  static String _intervalUnitLabel(String frequency) {
    return switch (frequency) {
      'daily' => 'Tage',
      'weekly' => 'Wochen',
      'monthly' => 'Monate',
      'yearly' => 'Jahre',
      _ => '',
    };
  }

  Widget _buildRecurrenceSection(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Row(
        children: [
          Icon(Icons.repeat, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text('Wiederholung', style: theme.textTheme.titleSmall),
        ],
      ),
      subtitle: Text(
        _recurrenceRules.isEmpty
            ? 'Keine Wiederholung'
            : '${_recurrenceRules.length} Regel(n)',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Mehrere Regeln werden kombiniert (z. B. Di und Do).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...List.generate(_recurrenceRules.length, (i) {
          return _buildRecurrenceRuleCard(context, i);
        }),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _recurrenceRules.add(
                  EventRecurrenceRule(
                    frequency: 'weekly',
                    interval: 1,
                    byWeekday: [_startDate.weekday],
                  ),
                );
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Regel hinzufügen'),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceRuleCard(BuildContext context, int index) {
    final theme = Theme.of(context);
    final r = _recurrenceRules[index];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: r.frequency,
                    decoration: const InputDecoration(labelText: 'Rhythmus'),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Täglich')),
                      DropdownMenuItem(value: 'weekly', child: Text('Wöchentlich')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monatlich')),
                      DropdownMenuItem(value: 'yearly', child: Text('Jährlich')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _recurrenceRules[index] = r.copyWith(
                          frequency: v,
                          clearByWeekday: v != 'weekly',
                        );
                      });
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Regel entfernen',
                  onPressed: () {
                    setState(() => _recurrenceRules.removeAt(index));
                  },
                  icon: Icon(Icons.close, color: theme.colorScheme.error),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Intervall', style: theme.textTheme.labelLarge),
                const Spacer(),
                IconButton(
                  onPressed: r.interval <= 1
                      ? null
                      : () => setState(() {
                            _recurrenceRules[index] =
                                r.copyWith(interval: r.interval - 1);
                          }),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('${r.interval}', style: theme.textTheme.titleMedium),
                IconButton(
                  onPressed: () => setState(() {
                    _recurrenceRules[index] =
                        r.copyWith(interval: r.interval + 1);
                  }),
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Text(
              'Alle ${r.interval} ${_intervalUnitLabel(r.frequency)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (r.frequency == 'weekly') ...[
              const SizedBox(height: 8),
              Text('Wochentage', style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: List.generate(7, (di) {
                  final wd = di + 1;
                  final sel = r.byWeekday?.contains(wd) ?? false;
                  return FilterChip(
                    label: Text(_weekdayShort[di]),
                    selected: sel,
                    onSelected: (on) {
                      setState(() {
                        final cur = {...?r.byWeekday};
                        if (on) {
                          cur.add(wd);
                        } else {
                          cur.remove(wd);
                        }
                        final list = cur.toList()..sort();
                        _recurrenceRules[index] = r.copyWith(
                          byWeekday: list.isEmpty ? [_startDate.weekday] : list,
                        );
                      });
                    },
                  );
                }),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: r.until ?? _startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        locale: const Locale('de'),
                      );
                      if (picked != null) {
                        setState(() {
                          _recurrenceRules[index] =
                              r.copyWith(until: picked, clearCount: true);
                        });
                      }
                    },
                    icon: const Icon(Icons.event, size: 18),
                    label: Text(
                      r.until != null
                          ? 'Bis ${AppDateUtils.formatDate(r.until!)}'
                          : 'Ende (optional)',
                    ),
                  ),
                ),
                if (r.until != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _recurrenceRules[index] = r.copyWith(clearUntil: true);
                      });
                    },
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Max. Anzahl (optional)',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                if (r.count != null) ...[
                  IconButton(
                    onPressed: r.count! <= 1
                        ? null
                        : () => setState(() {
                              _recurrenceRules[index] =
                                  r.copyWith(count: r.count! - 1);
                            }),
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text('${r.count}', style: theme.textTheme.titleMedium),
                  IconButton(
                    onPressed: () => setState(() {
                      _recurrenceRules[index] =
                          r.copyWith(count: (r.count ?? 0) + 1);
                    }),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Limit entfernen',
                    onPressed: () => setState(() {
                      _recurrenceRules[index] = r.copyWith(clearCount: true);
                    }),
                    icon: const Icon(Icons.clear),
                  ),
                ] else
                  TextButton(
                    onPressed: () => setState(() {
                      _recurrenceRules[index] = r.copyWith(count: 10);
                    }),
                    child: const Text('Limit setzen'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final h = hex.replaceAll('#', '').trim();
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    return null;
  }

  String _hexRgb(Color c) {
    final r = (c.r * 255.0).round() & 0xff;
    final g = (c.g * 255.0).round() & 0xff;
    final b = (c.b * 255.0).round() & 0xff;
    return '#${r.toRadixString(16).padLeft(2, '0')}'
        '${g.toRadixString(16).padLeft(2, '0')}'
        '${b.toRadixString(16).padLeft(2, '0')}';
  }

  Future<void> _pickEventColor(
    BuildContext context,
    String? categoryFallbackHex,
  ) async {
    var pick = _parseHexColor(_eventColorHex) ??
        _parseHexColor(categoryFallbackHex) ??
        Theme.of(context).colorScheme.primary;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminfarbe'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pick,
            onColorChanged: (c) => pick = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.85,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _eventColorHex = null);
              Navigator.pop(ctx);
            },
            child: const Text('Kategoriefarbe'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _eventColorHex = _hexRgb(pick));
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventColorSection(
    BuildContext context,
    List<Category> categories,
  ) {
    final theme = Theme.of(context);
    Category? cat;
    if (_categoryId != null) {
      for (final c in categories) {
        if (c.id == _categoryId) {
          cat = c;
          break;
        }
      }
    }
    final fallbackHex = cat?.color;
    final displayHex = _eventColorHex;
    final previewColor = _parseHexColor(displayHex) ??
        _parseHexColor(fallbackHex) ??
        theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Terminfarbe', style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: previewColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
          ),
          title: Text(
            displayHex ??
                (fallbackHex != null ? 'Wie Kategorie' : 'Wie Kategorie / App'),
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            displayHex == null
                ? 'Optional: nur diesen Termin anders einfärben.'
                : 'Überschreibt die Kategoriefarbe in der Ansicht.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (displayHex != null)
                TextButton(
                  onPressed: () => setState(() => _eventColorHex = null),
                  child: const Text('Zurücksetzen'),
                ),
              TextButton(
                onPressed: () => _pickEventColor(context, fallbackHex),
                child: const Text('Wählen'),
              ),
            ],
          ),
        ),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/family_member.dart';
import '../../../shared/widgets/category_picker.dart';
import '../../../shared/widgets/member_chip.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../core/api/api_client.dart';

final _categoriesProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final _membersProvider = FutureProvider<List<FamilyMember>>((ref) {
  return ref.watch(memberRepositoryProvider).getMembers();
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
  bool _saving = false;

  bool get _isEditing => widget.event != null;

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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

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
      };
      final repo = ref.read(eventRepositoryProvider);
      if (_isEditing) {
        await repo.updateEvent(widget.event!.id, data);
      } else {
        await repo.createEvent(data);
      }
      if (mounted) Navigator.of(context).pop(true);
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
        title: const Text('Termin loeschen?'),
        content: Text('Soll "${widget.event!.title}" wirklich geloescht werden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Loeschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(widget.event!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Beschreibung', prefixIcon: Icon(Icons.notes)),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Ganztaegig'),
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
                    }),
                  ),
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
                final picked = await showTimePicker(context: context, initialTime: time);
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../../categories/data/category_repository.dart';
import '../../categories/domain/category.dart' as cat;
import '../../members/data/member_repository.dart';
import '../../members/domain/family_member.dart';
import '../../../shared/widgets/category_picker.dart';
import '../../../shared/widgets/member_chip.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/utils/date_utils.dart' as utils;

class TodoFormDialog extends ConsumerStatefulWidget {
  final Todo? todo;

  const TodoFormDialog({super.key, this.todo});

  @override
  ConsumerState<TodoFormDialog> createState() => _TodoFormDialogState();
}

class _TodoFormDialogState extends ConsumerState<TodoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _priority = 'none';
  DateTime? _dueDate;
  int? _categoryId;
  Set<int> _memberIds = {};
  bool _requiresMultiple = false;
  bool _saving = false;

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleController = TextEditingController(text: t?.title ?? '');
    _descController = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? 'none';
    _dueDate = t?.dueDate;
    _categoryId = t?.categoryId;
    _memberIds = (t?.memberIds ?? []).toSet();
    _requiresMultiple = t?.requiresMultiple ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        'priority': _priority,
        'due_date': _dueDate?.toIso8601String(),
        'category_id': _categoryId,
        'member_ids': _memberIds.toList(),
        'requires_multiple': _requiresMultiple,
      };
      final repo = ref.read(todoRepositoryProvider);
      if (_isEditing) {
        await repo.updateTodo(widget.todo!.id, data);
      } else {
        await repo.createTodo(data);
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
        title: const Text('Aufgabe loeschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Loeschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(todoRepositoryProvider).deleteTodo(widget.todo!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(FutureProvider<List<cat.Category>>((ref) {
      return ref.watch(categoryRepositoryProvider).getCategories();
    })).valueOrNull ?? [];
    final members = ref.watch(FutureProvider<List<FamilyMember>>((ref) {
      return ref.watch(memberRepositoryProvider).getMembers();
    })).valueOrNull ?? [];

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
                      Expanded(child: Text(_isEditing ? 'Aufgabe bearbeiten' : 'Neue Aufgabe', style: Theme.of(context).textTheme.titleLarge)),
                      if (_isEditing) IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _delete),
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
                  TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Beschreibung', prefixIcon: Icon(Icons.notes)), maxLines: 2),
                  const SizedBox(height: 12),
                  PrioritySelector(value: _priority, onChanged: (v) => setState(() => _priority = v)),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Faelligkeitsdatum',
                        prefixIcon: const Icon(Icons.event),
                        suffixIcon: _dueDate != null
                            ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null))
                            : null,
                      ),
                      child: Text(_dueDate != null ? utils.AppDateUtils.formatDate(_dueDate!) : 'Nicht gesetzt'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CategoryPicker(categories: categories, selectedId: _categoryId, onChanged: (v) => setState(() => _categoryId = v)),
                  const SizedBox(height: 12),
                  Text('Zugewiesen an', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  MemberChipRow(members: members, selectedIds: _memberIds, onToggle: (id) => setState(() => _memberIds.contains(id) ? _memberIds.remove(id) : _memberIds.add(id))),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Mehrere Personen erforderlich'),
                    value: _requiresMultiple,
                    onChanged: (v) => setState(() => _requiresMultiple = v),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Abbrechen')),
                      const SizedBox(width: 8),
                      FilledButton(onPressed: _saving ? null : _save, child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_isEditing ? 'Speichern' : 'Erstellen')),
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
}

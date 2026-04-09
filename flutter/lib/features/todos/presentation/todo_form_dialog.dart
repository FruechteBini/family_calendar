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
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../shared/widgets/form_input_decoration.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/utils/date_utils.dart' as utils;
import 'proposal_sheet.dart';

final _formCategoriesProvider = FutureProvider<List<cat.Category>>((ref) async {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

final _formMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  return ref.watch(memberRepositoryProvider).getMembers();
});

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
  late TextEditingController _proposalMessageController;
  String _priority = 'none';
  DateTime? _dueDate;
  DateTime? _proposalDateTime;
  int? _categoryId;
  bool _isPersonal = false;
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
    _proposalMessageController = TextEditingController();
    _priority = t?.priority ?? 'none';
    _dueDate = t?.dueDate;
    _categoryId = t?.categoryId;
    _isPersonal = t?.isPersonal ?? false;
    _memberIds = (t?.memberIds ?? []).toSet();
    _requiresMultiple = t?.requiresMultiple ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isEditing || _isPersonal) return;
      final mid = ref.read(authStateProvider).user?.memberId;
      if (mid != null && _memberIds.isEmpty) {
        setState(() => _memberIds = {mid});
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _proposalMessageController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descController.text.trim().isEmpty
            ? null
            : _descController.text.trim(),
        if (_priority != 'none') 'priority': _priority,
        'due_date': _dueDate?.toIso8601String(),
        'category_id': _categoryId,
      };
      if (!_isEditing) {
        data['is_personal'] = _isPersonal;
      }
      if (!_isPersonal) {
        data['member_ids'] = _memberIds.toList();
        data['requires_multiple'] = _requiresMultiple;
      } else {
        data['requires_multiple'] = false;
      }
      final repo = ref.read(todoRepositoryProvider);
      Todo saved;
      if (_isEditing) {
        saved = await repo.updateTodo(widget.todo!.id, data);
      } else {
        saved = await repo.createTodo(data);
      }

      // Optional: send proposal immediately after save.
      if (!_isPersonal &&
          _requiresMultiple &&
          _memberIds.length >= 2 &&
          _proposalDateTime != null) {
        try {
          await repo.createProposal(saved.id, {
            'proposed_date': _proposalDateTime!.toIso8601String(),
            'message': _proposalMessageController.text.trim().isEmpty
                ? null
                : _proposalMessageController.text.trim(),
          });
          if (mounted) {
            showAppToast(
              context,
              message: 'Terminvorschlag gesendet',
              type: ToastType.success,
            );
          }
        } on ApiException catch (e) {
          if (mounted) {
            showAppToast(context, message: e.message, type: ToastType.error);
          }
        }
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted)
        showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Todo löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(todoRepositoryProvider).deleteTodo(widget.todo!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted)
        showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(_formCategoriesProvider);
    final membersAsync = ref.watch(_formMembersProvider);

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
                              _isEditing ? 'Todo bearbeiten' : 'Neues Todo',
                              style: Theme.of(context).textTheme.titleLarge)),
                      if (_isEditing)
                        IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            onPressed: _delete),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Persönliches Todo'),
                    subtitle: const Text('Nur für dich sichtbar und abhakbar'),
                    value: _isPersonal,
                    onChanged: _isEditing
                        ? null
                        : (v) => setState(() {
                              _isPersonal = v;
                              if (_isPersonal) {
                                _memberIds = {};
                                _requiresMultiple = false;
                                _proposalDateTime = null;
                                _proposalMessageController.clear();
                              } else {
                                final mid =
                                    ref.read(authStateProvider).user?.memberId;
                                if (mid != null) {
                                  _memberIds = {mid};
                                }
                              }
                            }),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: appFormInputDecoration(
                      context,
                      labelText: 'Titel',
                      prefixIcon: const Icon(Icons.title),
                    ),
                    autofocus: !_isEditing,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Titel erforderlich'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  LabeledMultilineTextField(
                    label: 'Beschreibung',
                    controller: _descController,
                    hintText:
                        'Optional — Notizen, Links oder eine kurze Checkliste …',
                  ),
                  const SizedBox(height: 12),
                  PrioritySelector(
                      value: _priority,
                      onChanged: (v) => setState(() => _priority = v)),
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
                      decoration: appFormInputDecoration(
                        context,
                        labelText: 'Fälligkeitsdatum',
                        prefixIcon: const Icon(Icons.event),
                        suffixIcon: _dueDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () =>
                                    setState(() => _dueDate = null))
                            : null,
                      ),
                      child: Text(_dueDate != null
                          ? utils.AppDateUtils.formatDate(_dueDate!)
                          : 'Nicht gesetzt'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  categoriesAsync.when(
                    data: (categories) => CategoryPicker(
                      categories: categories,
                      selectedId: _categoryId,
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    loading: () => DropdownButtonFormField<int?>(
                      isExpanded: true,
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Kategorien werden geladen…'),
                        ),
                      ],
                      onChanged: null,
                      decoration: appFormInputDecoration(
                        context,
                        labelText: 'Kategorie',
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                    ),
                    error: (_, __) => DropdownButtonFormField<int?>(
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem<int?>(
                          value: null,
                          child:
                              Text('Kategorien konnten nicht geladen werden'),
                        ),
                      ],
                      onChanged: null,
                      decoration: appFormInputDecoration(
                        context,
                        labelText: 'Kategorie',
                        prefixIcon: const Icon(Icons.label_outline),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!_isPersonal) ...[
                    Text('Zugewiesen an',
                        style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    membersAsync.when(
                      data: (members) => MemberChipRow(
                        members: members,
                        selectedIds: _memberIds,
                        onToggle: (id) => setState(() => _memberIds.contains(id)
                            ? _memberIds.remove(id)
                            : _memberIds.add(id)),
                      ),
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(minHeight: 2),
                      ),
                      error: (e, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                            'Familienmitglieder konnten nicht geladen werden: $e'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Mehrere Personen erforderlich'),
                      value: _requiresMultiple,
                      onChanged: (v) => setState(() => _requiresMultiple = v),
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ],
                  if (!_isPersonal && _requiresMultiple) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Terminvorschlag',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateTimePicker(
                          context,
                          _proposalDateTime ?? DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() => _proposalDateTime = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: appFormInputDecoration(
                          context,
                          labelText: 'Vorschlag (Datum & Uhrzeit)',
                          prefixIcon: const Icon(Icons.schedule),
                          suffixIcon: _proposalDateTime != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () =>
                                      setState(() => _proposalDateTime = null),
                                )
                              : null,
                        ),
                        child: Text(
                          _proposalDateTime != null
                              ? utils.AppDateUtils.formatDateTime(
                                  _proposalDateTime!)
                              : 'Nicht gesetzt',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    LabeledMultilineTextField(
                      label: 'Nachricht (optional)',
                      controller: _proposalMessageController,
                      hintText:
                          'Optional — Kurzer Hinweis zum Terminvorschlag …',
                      minLines: 3,
                      maxLines: 6,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Hinweis: Der Vorschlag wird beim Speichern an alle zugewiesenen Personen gesendet.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Abbrechen')),
                      const SizedBox(width: 8),
                      FilledButton(
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : Text(_isEditing ? 'Speichern' : 'Erstellen')),
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

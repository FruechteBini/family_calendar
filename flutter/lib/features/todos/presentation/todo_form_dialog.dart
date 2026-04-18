import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import '../data/todo_repository.dart';
import '../domain/todo.dart';
import '../../categories/categories_providers.dart';
import '../../categories/data/category_repository.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/family_member.dart';
import '../../../shared/widgets/category_accent_chips.dart';
import '../../../shared/widgets/category_picker.dart';
import '../../../shared/widgets/member_chip.dart';
import '../../../shared/widgets/priority_badge.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../shared/widgets/form_input_decoration.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/sync/mutation_refresh.dart';
import '../../../shared/utils/date_utils.dart' as utils;
import 'proposal_sheet.dart';
import '../../notifications/presentation/widgets/notification_level_picker.dart';
import '../../notes/data/note_repository.dart';
import '../../notes/domain/note.dart';
import '../../notes/domain/note_todo_prefill.dart';
import '../domain/todo_attachment.dart';
import 'todo_attachment_helpers.dart';
import 'todo_detail_screen.dart';

class _PendingFile {
  final String filename;
  final String? filePath;
  final Uint8List? bytes;

  const _PendingFile({
    required this.filename,
    this.filePath,
    this.bytes,
  });
}

final _formMembersProvider = FutureProvider<List<FamilyMember>>((ref) async {
  return ref.watch(memberRepositoryProvider).getMembers();
});

class TodoFormDialog extends ConsumerStatefulWidget {
  final Todo? todo;
  /// When set (and [todo] is null), opens like a new todo prefilled from this note.
  /// After create, the note is archived if still active.
  final Note? convertFromNote;

  const TodoFormDialog({
    super.key,
    this.todo,
    this.convertFromNote,
  }) : assert(
          todo == null || convertFromNote == null,
          'todo and convertFromNote are mutually exclusive',
        );

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
  int? _notificationLevelId;
  bool _saving = false;
  final List<TodoAttachment> _existingAttachments = [];
  final Set<int> _removedAttachmentIds = {};
  final List<_PendingFile> _pendingFiles = [];

  bool get _isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    final fromNote = widget.convertFromNote;
    _proposalMessageController = TextEditingController();
    if (t != null) {
      _titleController = TextEditingController(text: t.title);
      _descController = TextEditingController(text: t.description ?? '');
      _priority = t.priority;
      _dueDate = t.dueDate;
      _categoryId = t.categoryId;
      _isPersonal = t.isPersonal;
      _memberIds = t.memberIds.toSet();
      _requiresMultiple = t.requiresMultiple;
      _notificationLevelId = t.notificationLevelId;
      _existingAttachments.addAll(t.attachments);
    } else if (fromNote != null) {
      final p = noteTodoPrefillFromNote(fromNote);
      _titleController = TextEditingController(text: p.title);
      _descController = TextEditingController(text: p.description ?? '');
      _priority = 'medium';
      _dueDate = null;
      _categoryId = null;
      _isPersonal = p.isPersonal;
      _memberIds = {};
      _requiresMultiple = false;
      _notificationLevelId = null;
    } else {
      _titleController = TextEditingController();
      _descController = TextEditingController();
      _priority = 'none';
      _dueDate = null;
      _categoryId = null;
      _isPersonal = false;
      _memberIds = {};
      _requiresMultiple = false;
      _notificationLevelId = null;
    }
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

  Future<void> _addPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: source);
    if (x == null) return;
    final preview = await x.readAsBytes();
    if (kIsWeb) {
      setState(() {
        _pendingFiles.add(_PendingFile(filename: x.name, bytes: preview));
      });
    } else {
      setState(() {
        _pendingFiles.add(
          _PendingFile(
            filename: path.basename(x.path),
            filePath: x.path,
            bytes: preview,
          ),
        );
      });
    }
  }

  Future<void> _addVideo() async {
    final picker = ImagePicker();
    final x = await picker.pickVideo(source: ImageSource.gallery);
    if (x == null) return;
    if (kIsWeb) {
      final b = await x.readAsBytes();
      setState(() {
        _pendingFiles.add(_PendingFile(filename: x.name, bytes: b));
      });
    } else {
      setState(() {
        _pendingFiles.add(
          _PendingFile(
            filename: path.basename(x.path),
            filePath: x.path,
          ),
        );
      });
    }
  }

  Future<void> _addDocuments() async {
    final r = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
    );
    if (r == null || r.files.isEmpty) return;
    setState(() {
      for (final f in r.files) {
        final name = f.name;
        if (name.isEmpty) continue;
        if (kIsWeb && f.bytes != null) {
          _pendingFiles.add(_PendingFile(filename: name, bytes: f.bytes));
        } else if (f.path != null && f.path!.isNotEmpty) {
          _pendingFiles.add(_PendingFile(filename: name, filePath: f.path));
        }
      }
    });
  }

  Future<void> _showAttachMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Foto aus Galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _addPhoto(ImageSource.gallery);
              },
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Foto aufnehmen'),
                onTap: () {
                  Navigator.pop(ctx);
                  _addPhoto(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined),
              title: const Text('Video aus Galerie'),
              onTap: () {
                Navigator.pop(ctx);
                _addVideo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Datei auswählen'),
              onTap: () {
                Navigator.pop(ctx);
                _addDocuments();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removePending(int index) {
    setState(() => _pendingFiles.removeAt(index));
  }

  void _removeExisting(TodoAttachment a) {
    setState(() => _removedAttachmentIds.add(a.id));
  }

  Widget _filePlaceholder(ThemeData theme, bool isVideo, String name) {
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isVideo ? Icons.videocam_outlined : Icons.insert_drive_file_outlined,
            size: 28,
          ),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingThumb(_PendingFile p, int index, ThemeData theme) {
    final isImg = p.filename.toLowerCase().endsWith('.png') ||
        p.filename.toLowerCase().endsWith('.jpg') ||
        p.filename.toLowerCase().endsWith('.jpeg') ||
        p.filename.toLowerCase().endsWith('.gif') ||
        p.filename.toLowerCase().endsWith('.webp');
    final isVid = p.filename.toLowerCase().endsWith('.mp4') ||
        p.filename.toLowerCase().endsWith('.mov') ||
        p.filename.toLowerCase().endsWith('.webm');
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 88,
              height: 88 * 9 / 16,
              child: isImg && p.bytes != null
                  ? Image.memory(
                      p.bytes!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _filePlaceholder(theme, isVid, p.filename),
                    )
                  : _filePlaceholder(theme, isVid, p.filename),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Material(
              color: theme.colorScheme.errorContainer,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _removePending(index),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close,
                      size: 16, color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExistingThumb(TodoAttachment a, ThemeData theme) {
    if (_removedAttachmentIds.contains(a.id)) return const SizedBox.shrink();
    final headers = todoImageRequestHeaders(ref);
    final url = todoAttachmentFullUrl(ref, a);
    final isImg = todoAttachmentIsImage(a);
    final isVid = todoAttachmentIsVideo(a);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 88,
              height: 88 * 9 / 16,
              child: isImg
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      httpHeaders: headers,
                      placeholder: (_, __) => const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) =>
                          _filePlaceholder(theme, isVid, a.filename),
                    )
                  : _filePlaceholder(theme, isVid, a.filename),
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: Material(
              color: theme.colorScheme.errorContainer,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _removeExisting(a),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close,
                      size: 16, color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        'notification_level_id': _notificationLevelId,
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
      late final int todoId;
      if (_isEditing) {
        await repo.updateTodo(widget.todo!.id, data);
        todoId = widget.todo!.id;
        for (final id in _removedAttachmentIds) {
          await repo.deleteTodoAttachment(todoId, id);
        }
      } else {
        final saved = await repo.createTodo(data);
        todoId = saved.id;
        final src = widget.convertFromNote;
        if (src != null && !src.isArchived && mounted) {
          try {
            await ref.read(noteRepositoryProvider).toggleArchive(src.id);
          } on ApiException catch (e) {
            if (mounted) {
              showAppToast(
                context,
                message:
                    'Todo erstellt, Notiz konnte nicht archiviert werden: ${e.message}',
                type: ToastType.warning,
              );
            }
          }
        }
      }
      for (final p in _pendingFiles) {
        await repo.uploadTodoAttachmentData(
          todoId,
          filename: p.filename,
          filePath: p.filePath,
          bytes: p.bytes,
        );
      }

      // Optional: send proposal immediately after save.
      if (!_isPersonal &&
          _requiresMultiple &&
          _memberIds.length >= 2 &&
          _proposalDateTime != null) {
        try {
          await repo.createProposal(todoId, {
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
      refreshAfterMutation(ref);
      ref.invalidate(todoDetailProvider(widget.todo!.id));
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted)
        showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _openCreateTodoCategoryDialog() async {
    final name = TextEditingController();
    var selectedHex = kCategoryPresetHexColors.first;
    final icon = TextEditingController(text: '\u{1F4C1}');
    try {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => AlertDialog(
            title: const Text('Neue Kategorie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: appFormInputDecoration(
                      ctx,
                      labelText: 'Name',
                      prefixIcon: const Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  CategoryColorPickerTile(
                    hex: selectedHex,
                    onHexChanged: (h) => setModal(() => selectedHex = h),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: icon,
                    decoration: appFormInputDecoration(
                      ctx,
                      labelText: 'Icon (Emoji)',
                      prefixIcon: const Icon(Icons.emoji_emotions_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Abbrechen'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Anlegen'),
              ),
            ],
          ),
        ),
      );
      if (ok != true || !mounted) return;
      final trimmed = name.text.trim();
      if (trimmed.isEmpty) {
        showAppToast(context,
            message: 'Name erforderlich', type: ToastType.error);
        return;
      }
      final created =
          await ref.read(categoryRepositoryProvider).createCategory({
        'name': trimmed,
        'color': selectedHex.trim(),
        'icon': icon.text.trim().isEmpty ? '\u{1F4C1}' : icon.text.trim(),
      });
      ref.invalidate(categoriesListProvider);
      setState(() => _categoryId = created.id);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    } finally {
      name.dispose();
      icon.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);
    final membersAsync = ref.watch(_formMembersProvider);
    final theme = Theme.of(context);
    final visibleExisting = _existingAttachments
        .where((a) => !_removedAttachmentIds.contains(a.id))
        .toList();

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
                              _isEditing
                                  ? 'Todo bearbeiten'
                                  : widget.convertFromNote != null
                                      ? 'Todo aus Notiz'
                                      : 'Neues Todo',
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      categoriesAsync.when(
                        data: (categories) => CategoryPicker(
                          categories: categories,
                          selectedId: _categoryId,
                          onChanged: (v) => setState(() => _categoryId = v),
                        ),
                        loading: () => DropdownButtonFormField<int?>(
                          isExpanded: true,
                          items: const [
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
                              child: Text(
                                  'Kategorien konnten nicht geladen werden'),
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
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed:
                              _saving ? null : _openCreateTodoCategoryDialog,
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          label: const Text('Neue Kategorie'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  NotificationLevelPicker(
                    value: _notificationLevelId,
                    onChanged: _isPersonal
                        ? (_) {}
                        : (v) => setState(() => _notificationLevelId = v),
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
                  const SizedBox(height: 16),
                  Text('Anhänge', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _showAttachMenu,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Datei, Foto oder Video'),
                  ),
                  if (visibleExisting.isNotEmpty || _pendingFiles.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 88 * 9 / 16 + 8,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...visibleExisting.map(
                            (a) => KeyedSubtree(
                              key: ValueKey('ex-${a.id}'),
                              child: _buildExistingThumb(a, theme),
                            ),
                          ),
                          ..._pendingFiles.asMap().entries.map((e) {
                            return KeyedSubtree(
                              key: ValueKey('pd-${e.key}-${e.value.filename}'),
                              child: _buildPendingThumb(e.value, e.key, theme),
                            );
                          }),
                        ],
                      ),
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

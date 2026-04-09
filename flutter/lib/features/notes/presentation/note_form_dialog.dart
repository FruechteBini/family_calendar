import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_category_repository.dart';
import '../data/note_repository.dart';
import '../data/note_tag_repository.dart';
import '../domain/note.dart';

final _urlInText = RegExp(r'https?://[^\s]+', caseSensitive: false);

final _noteFormCategoriesProvider =
    FutureProvider((ref) => ref.read(noteCategoryRepositoryProvider).getCategories());

final _noteFormTagsProvider =
    FutureProvider((ref) => ref.read(noteTagRepositoryProvider).getTags());

String _colorToHex(Color c) {
  final argb = c.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

class NoteFormDialog extends ConsumerStatefulWidget {
  final Note? note;

  const NoteFormDialog({super.key, this.note});

  @override
  ConsumerState<NoteFormDialog> createState() => _NoteFormDialogState();
}

class _NoteFormDialogState extends ConsumerState<NoteFormDialog> {
  late NoteType _type;
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _url = TextEditingController();
  bool _personal = false;
  int? _categoryId;
  final Set<int> _tagIds = {};
  Color? _noteColor;
  DateTime? _reminder;
  final List<TextEditingController> _checkLines = [];
  final List<bool> _checkDone = [];
  bool _saving = false;
  String? _dupWarning;
  LinkPreview? _preview;

  bool get _isEdit => widget.note != null;

  @override
  void initState() {
    super.initState();
    final n = widget.note;
    if (n != null) {
      _type = n.type;
      _title.text = n.title;
      _content.text = n.content ?? '';
      _url.text = n.url ?? '';
      _personal = n.isPersonal;
      _categoryId = n.category?.id;
      _tagIds.addAll(n.tags.map((t) => t.id));
      if (n.color != null && n.color!.length == 7) {
        try {
          _noteColor = Color(int.parse(n.color!.replaceFirst('#', '0xFF')));
        } catch (_) {}
      }
      _reminder = n.reminderAt;
      for (final it in n.checklistItems ?? []) {
        _checkLines.add(TextEditingController(text: it.text));
        _checkDone.add(it.checked);
      }
    } else {
      _type = NoteType.text;
    }
    if (_checkLines.isEmpty) {
      _checkLines.add(TextEditingController());
      _checkDone.add(false);
    }
    _content.addListener(_onContentChanged);
    _url.addListener(() => setState(() {}));
  }

  void _onContentChanged() {
    if (_type != NoteType.text) return;
    final m = _urlInText.firstMatch(_content.text);
    if (m != null && mounted) {
      setState(() => _dupWarning = null);
    }
  }

  @override
  void dispose() {
    _content.removeListener(_onContentChanged);
    _title.dispose();
    _content.dispose();
    _url.dispose();
    for (final c in _checkLines) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchPreview() async {
    final u = _url.text.trim();
    if (u.isEmpty) return;
    try {
      final p = await ref.read(noteRepositoryProvider).previewLink(u);
      if (mounted) setState(() => _preview = p);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _checkDup() async {
    final u = _url.text.trim();
    if (u.isEmpty) return;
    try {
      final d = await ref.read(noteRepositoryProvider).checkDuplicateLink(u);
      if (mounted) {
        setState(() {
          _dupWarning = d.exists
              ? 'Dieser Link existiert bereits: ${d.title ?? "Notiz #${d.noteId}"}'
              : null;
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _checklistPayload() {
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < _checkLines.length; i++) {
      final t = _checkLines[i].text.trim();
      if (t.isEmpty) continue;
      out.add({'text': t, 'checked': i < _checkDone.length ? _checkDone[i] : false});
    }
    return out;
  }

  Future<void> _save() async {
    if (_type == NoteType.text) {
      if (_title.text.trim().isEmpty && _content.text.trim().isEmpty) {
        showAppToast(context,
            message: 'Titel oder Inhalt erforderlich', type: ToastType.error);
        return;
      }
    }
    if (_type == NoteType.link && _url.text.trim().isEmpty) {
      showAppToast(context, message: 'URL erforderlich', type: ToastType.error);
      return;
    }
    if (_type == NoteType.checklist && _checklistPayload().isEmpty) {
      showAppToast(context,
          message: 'Mindestens ein Listenpunkt erforderlich',
          type: ToastType.error);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(noteRepositoryProvider);
    final data = <String, dynamic>{
      'title': _title.text.trim(),
      'type': switch (_type) {
        NoteType.text => 'text',
        NoteType.link => 'link',
        NoteType.checklist => 'checklist',
      },
      'is_personal': _personal,
      'category_id': _categoryId,
      'tag_ids': _tagIds.toList(),
      'reminder_at': _reminder?.toUtc().toIso8601String(),
      if (_noteColor != null) 'color': _colorToHex(_noteColor!),
    };

    switch (_type) {
      case NoteType.text:
        data['content'] = _content.text;
        data['url'] = null;
        break;
      case NoteType.link:
        data['url'] = _url.text.trim();
        data['content'] = null;
        break;
      case NoteType.checklist:
        data['checklist_items'] = _checklistPayload();
        data['content'] = null;
        data['url'] = null;
        break;
    }

    try {
      if (_isEdit) {
        await repo.updateNote(widget.note!.id, data);
      } else {
        await repo.createNote(data);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickImage(int noteId) async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x == null) return;
    try {
      await ref.read(noteRepositoryProvider).uploadAttachment(noteId, x.path);
      if (mounted) {
        showAppToast(context, message: 'Anhang hochgeladen', type: ToastType.success);
        setState(() {});
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catsAsync = ref.watch(_noteFormCategoriesProvider);
    final tagsAsync = ref.watch(_noteFormTagsProvider);

    final detectedUrl = _type == NoteType.text
        ? _urlInText.firstMatch(_content.text)?.group(0)
        : null;

    return AlertDialog(
      title: Text(_isEdit ? 'Notiz bearbeiten' : 'Neue Notiz'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<NoteType>(
                segments: const [
                  ButtonSegment(value: NoteType.text, label: Text('Text')),
                  ButtonSegment(value: NoteType.link, label: Text('Link')),
                  ButtonSegment(
                      value: NoteType.checklist, label: Text('Liste')),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  setState(() {
                    _type = s.first;
                    _dupWarning = null;
                    _preview = null;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Titel (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_type == NoteType.text) ...[
                TextField(
                  controller: _content,
                  decoration: const InputDecoration(
                    labelText: 'Inhalt (Markdown)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 4,
                  maxLines: 12,
                ),
                if (detectedUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _type = NoteType.link;
                          _url.text = detectedUrl;
                        });
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Als Link-Notiz speichern?'),
                    ),
                  ),
              ],
              if (_type == NoteType.link) ...[
                TextField(
                  controller: _url,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    border: OutlineInputBorder(),
                  ),
                  onEditingComplete: () {
                    _fetchPreview();
                    _checkDup();
                  },
                ),
                TextButton(
                  onPressed: () {
                    _fetchPreview();
                    _checkDup();
                  },
                  child: const Text('Vorschau laden'),
                ),
                if (_dupWarning != null)
                  Text(_dupWarning!,
                      style: TextStyle(color: theme.colorScheme.error)),
                if (_preview != null &&
                    (_preview!.linkTitle != null ||
                        _preview!.linkThumbnailUrl != null))
                  ListTile(
                    leading: _preview!.linkThumbnailUrl != null
                        ? Image.network(_preview!.linkThumbnailUrl!, width: 48)
                        : const Icon(Icons.link),
                    title: Text(_preview!.linkTitle ?? ''),
                    subtitle: Text(_preview!.linkDomain ?? ''),
                  ),
              ],
              if (_type == NoteType.checklist) ...[
                Row(
                  children: [
                    Text('Punkte', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _checkLines.add(TextEditingController());
                          _checkDone.add(false);
                        });
                      },
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                ...List.generate(_checkLines.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Checkbox(
                          value: i < _checkDone.length ? _checkDone[i] : false,
                          onChanged: (v) {
                            setState(() {
                              while (_checkDone.length <= i) {
                                _checkDone.add(false);
                              }
                              _checkDone[i] = v ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: _checkLines[i],
                            decoration: const InputDecoration(
                              hintText: 'Eintrag',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _checkLines[i].dispose();
                              _checkLines.removeAt(i);
                              if (i < _checkDone.length) {
                                _checkDone.removeAt(i);
                              }
                            });
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              SwitchListTile(
                title: const Text('Persönlich'),
                subtitle: const Text('Nur für dich sichtbar'),
                value: _personal,
                onChanged: (v) => setState(() => _personal = v),
              ),
              catsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) => DropdownButtonFormField<int?>(
                  decoration: const InputDecoration(
                    labelText: 'Kategorie',
                    border: OutlineInputBorder(),
                  ),
                  value: _categoryId,
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Keine'),
                    ),
                    ...cats.map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              const SizedBox(height: 8),
              tagsAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (tags) => Wrap(
                  spacing: 6,
                  children: tags.map((t) {
                    final sel = _tagIds.contains(t.id);
                    return FilterChip(
                      label: Text(t.name),
                      selected: sel,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _tagIds.add(t.id);
                          } else {
                            _tagIds.remove(t.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Kartenfarbe'),
                trailing: _noteColor != null
                    ? CircleAvatar(backgroundColor: _noteColor, radius: 14)
                    : const Icon(Icons.palette_outlined),
                onTap: () async {
                  var pick = _noteColor ?? Colors.amber.shade100;
                  await showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Farbe'),
                      content: SingleChildScrollView(
                        child: ColorPicker(
                          pickerColor: pick,
                          onColorChanged: (c) => pick = c,
                          enableAlpha: false,
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _noteColor = null);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Keine'),
                        ),
                        FilledButton(
                          onPressed: () {
                            setState(() => _noteColor = pick);
                            Navigator.pop(ctx);
                          },
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                title: const Text('Erinnerung'),
                subtitle: Text(
                  _reminder == null
                      ? 'Keine'
                      : _reminder!.toLocal().toString().split('.').first,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.schedule),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _reminder ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                    );
                    if (d == null || !context.mounted) return;
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        _reminder ?? DateTime.now(),
                      ),
                    );
                    if (t == null) return;
                    setState(() {
                      _reminder = DateTime(d.year, d.month, d.day, t.hour, t.minute);
                    });
                  },
                ),
              ),
              if (_isEdit && widget.note!.attachments.isNotEmpty)
                Text(
                  '${widget.note!.attachments.length} Anhänge',
                  style: theme.textTheme.labelSmall,
                ),
              if (_isEdit)
                TextButton.icon(
                  onPressed: () => _pickImage(widget.note!.id),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Bild anhängen'),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEdit ? 'Speichern' : 'Erstellen'),
        ),
      ],
    );
  }
}

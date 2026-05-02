import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/category_accent_chips.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_category_repository.dart';
import '../data/note_repository.dart';
import '../data/note_tag_repository.dart';
import '../domain/note.dart';
import '../domain/note_attachment.dart';
import 'note_attachment_helpers.dart';
import '../logic/note_quick_capture.dart';

final _urlInText = RegExp(r'https?://[^\s]+', caseSensitive: false);

final _noteFormTagsProvider =
    FutureProvider((ref) => ref.read(noteTagRepositoryProvider).getTags());

String _colorToHex(Color c) {
  final argb = c.toARGB32();
  return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

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

class NoteFormDialog extends ConsumerStatefulWidget {
  final Note? note;
  /// Media from Android/iOS share sheet; mutually exclusive with [note].
  final List<SharedMediaFile>? sharedMedia;

  const NoteFormDialog({super.key, this.note, this.sharedMedia})
      : assert(
          note == null || sharedMedia == null,
          'note and sharedMedia are mutually exclusive',
        );

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
  bool _sharedMediaBusy = false;
  String? _dupWarning;
  LinkPreview? _preview;
  Timer? _linkUrlDebounce;
  Timer? _textUrlDebounce;

  final List<NoteAttachment> _existingAttachments = [];
  final Set<int> _removedAttachmentIds = {};
  final List<_PendingFile> _pendingFiles = [];

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
      _existingAttachments.addAll(n.attachments);
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
    _url.addListener(_onLinkUrlFieldChanged);

    if (widget.sharedMedia != null && widget.sharedMedia!.isNotEmpty) {
      _sharedMediaBusy = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_ingestSharedMedia());
      });
    }
  }

  Future<void> _ingestSharedMedia() async {
    final list = widget.sharedMedia;
    if (list == null || list.isEmpty) return;
    try {
      for (final f in list) {
        if (f.type != SharedMediaType.image &&
            f.type != SharedMediaType.video &&
            f.type != SharedMediaType.file) {
          continue;
        }
        final pathStr = f.path.trim();
        if (pathStr.isEmpty) continue;
        try {
          final xf = XFile(pathStr);
          final body = await xf.readAsBytes();
          var name = xf.name.trim();
          if (name.isEmpty) {
            name = path.basename(pathStr);
          }
          if (name.isEmpty) name = 'Anhang';
          if (!mounted) return;
          setState(() {
            _pendingFiles.add(_PendingFile(filename: name, bytes: body));
          });
        } catch (_) {
          if (kIsWeb) continue;
          if (!mounted) return;
          final base = path.basename(pathStr);
          setState(() {
            _pendingFiles.add(
              _PendingFile(
                filename: base.isNotEmpty ? base : 'Anhang',
                filePath: pathStr,
              ),
            );
          });
        }
      }
    } finally {
      if (mounted) setState(() => _sharedMediaBusy = false);
    }
  }

  void _onContentChanged() {
    if (_type != NoteType.text) return;
    final m = _urlInText.firstMatch(_content.text);
    if (m != null && mounted) {
      setState(() => _dupWarning = null);
    }
    _scheduleTextOnlyUrlPreview();
  }

  void _onLinkUrlFieldChanged() {
    if (!mounted) return;
    setState(() {});
    if (_type != NoteType.link) return;
    _linkUrlDebounce?.cancel();
    final u = _url.text.trim();
    if (u.isEmpty) {
      setState(() => _preview = null);
      return;
    }
    _linkUrlDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || _type != NoteType.link) return;
      unawaited(_fetchPreview(checkDup: true));
    });
  }

  void _scheduleTextOnlyUrlPreview() {
    _textUrlDebounce?.cancel();
    if (_type != NoteType.text) return;
    final raw = _content.text;
    final u = urlForLinkNote(raw);
    if (u == null || raw.trim() != u) {
      if (_preview != null && mounted) setState(() => _preview = null);
      return;
    }
    _textUrlDebounce = Timer(const Duration(milliseconds: 550), () {
      if (!mounted || _type != NoteType.text) return;
      unawaited(_fetchPreviewForStandaloneUrl(u));
    });
  }

  @override
  void dispose() {
    _linkUrlDebounce?.cancel();
    _textUrlDebounce?.cancel();
    _content.removeListener(_onContentChanged);
    _url.removeListener(_onLinkUrlFieldChanged);
    _title.dispose();
    _content.dispose();
    _url.dispose();
    for (final c in _checkLines) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchPreview({bool checkDup = false}) async {
    final u = _url.text.trim();
    if (u.isEmpty) return;
    try {
      final p = await ref.read(noteRepositoryProvider).previewLink(u);
      if (!mounted || _type != NoteType.link) return;
      setState(() {
        _preview = p;
        if (_title.text.trim().isEmpty &&
            p.linkTitle != null &&
            p.linkTitle!.trim().isNotEmpty) {
          _title.text = p.linkTitle!.trim();
        }
      });
      if (checkDup && mounted) await _checkDup();
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _fetchPreviewForStandaloneUrl(String u) async {
    if (u.isEmpty) return;
    try {
      final p = await ref.read(noteRepositoryProvider).previewLink(u);
      if (!mounted || _type != NoteType.text) return;
      final still = urlForLinkNote(_content.text);
      if (still == null || _content.text.trim() != still) return;
      setState(() {
        _preview = p;
        if (_title.text.trim().isEmpty &&
            p.linkTitle != null &&
            p.linkTitle!.trim().isNotEmpty) {
          _title.text = p.linkTitle!.trim();
        }
      });
    } on ApiException {
      // Vorschau optional — Notiz kann trotzdem ohne Metadaten gespeichert werden.
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

  bool _hasAnyAttachment() {
    final kept = _existingAttachments.where((a) => !_removedAttachmentIds.contains(a.id));
    return kept.isNotEmpty || _pendingFiles.isNotEmpty;
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
          ],
        ),
      ),
    );
  }

  void _removePending(int index) {
    setState(() => _pendingFiles.removeAt(index));
  }

  void _removeExisting(NoteAttachment a) {
    setState(() {
      _removedAttachmentIds.add(a.id);
    });
  }

  Widget _settingsRow({
    required String title,
    String? subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.textTheme.titleSmall),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: Center(child: trailing),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickColor() async {
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
  }

  Future<void> _pickReminder() async {
    if (!mounted) return;
    final d = await showDatePicker(
      context: context,
      initialDate: _reminder ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
        _reminder ?? DateTime.now(),
      ),
    );
    if (t == null || !mounted) return;
    setState(() {
      _reminder = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    });
  }

  Future<void> _openCreateNoteCategoryDialog() async {
    final name = TextEditingController();
    try {
      var hex = kCategoryPresetHexColors.first;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setModal) => AlertDialog(
            title: const Text('Neue Kategorie'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Farbe',
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  CategoryPresetColorRow(
                    selectedHex: hex,
                    onSelect: (h) => setModal(() => hex = h),
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
      try {
        final created =
            await ref.read(noteCategoryRepositoryProvider).createCategory({
          'name': trimmed,
          'color': hex,
          'icon': '\u{1F4DD}',
          'is_personal': _personal,
        });
        invalidateNoteCategoryCaches(ref);
        setState(() => _categoryId = created.id);
      } on ApiException catch (e) {
        if (mounted) {
          showAppToast(context, message: e.message, type: ToastType.error);
        }
      }
    } finally {
      name.dispose();
    }
  }

  Future<void> _save() async {
    if (_type == NoteType.text) {
      final hasBody =
          _title.text.trim().isNotEmpty || _content.text.trim().isNotEmpty;
      if (!hasBody && !_hasAnyAttachment()) {
        showAppToast(context,
            message: 'Titel, Inhalt oder Foto erforderlich', type: ToastType.error);
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

    if (_sharedMediaBusy) return;

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
      late final int noteId;
      if (_isEdit) {
        await repo.updateNote(widget.note!.id, data);
        noteId = widget.note!.id;
        for (final id in _removedAttachmentIds) {
          await repo.deleteAttachment(noteId, id);
        }
      } else {
        final created = await repo.createNote(data);
        noteId = created.id;
      }
      for (final p in _pendingFiles) {
        await repo.uploadAttachmentData(
          noteId,
          filename: p.filename,
          filePath: p.filePath,
          bytes: p.bytes,
        );
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

  Widget _buildPendingThumb(_PendingFile p, int index, ThemeData theme) {
    final isImg = filenameLooksImage(p.filename);
    final isVid = filenameLooksVideo(p.filename);
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
                  child: Icon(Icons.close, size: 16, color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _buildExistingThumb(NoteAttachment a, ThemeData theme) {
    if (_removedAttachmentIds.contains(a.id)) return const SizedBox.shrink();
    final headers = noteImageRequestHeaders(ref);
    final url = noteAttachmentFullUrl(ref, a);
    final isImg = noteAttachmentIsImage(a);
    final isVid = noteAttachmentIsVideo(a);
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
                  child: Icon(Icons.close, size: 16, color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catsAsync = ref.watch(noteCategoriesListProvider(_personal));
    final tagsAsync = ref.watch(_noteFormTagsProvider);

    final detectedUrl = _type == NoteType.text
        ? _urlInText.firstMatch(_content.text)?.group(0)
        : null;

    final visibleExisting =
        _existingAttachments.where((a) => !_removedAttachmentIds.contains(a.id)).toList();

    return AlertDialog(
      title: Text(_isEdit ? 'Notiz bearbeiten' : 'Neue Notiz'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_sharedMediaBusy)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              SegmentedButton<NoteType>(
                segments: const [
                  ButtonSegment(value: NoteType.text, label: Text('Text')),
                  ButtonSegment(value: NoteType.link, label: Text('Link')),
                  ButtonSegment(
                      value: NoteType.checklist, label: Text('Liste')),
                ],
                selected: {_type},
                onSelectionChanged: (s) {
                  _linkUrlDebounce?.cancel();
                  _textUrlDebounce?.cancel();
                  setState(() {
                    _type = s.first;
                    _dupWarning = null;
                    _preview = null;
                  });
                  if (s.first == NoteType.link && _url.text.trim().isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) unawaited(_fetchPreview(checkDup: true));
                    });
                  }
                  if (s.first == NoteType.text) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) _scheduleTextOnlyUrlPreview();
                    });
                  }
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
                    labelText: 'Inhalt (Markdown, optional)',
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
                        _textUrlDebounce?.cancel();
                        setState(() {
                          _type = NoteType.link;
                          _url.text = detectedUrl;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) unawaited(_fetchPreview(checkDup: true));
                        });
                      },
                      icon: const Icon(Icons.link),
                      label: const Text('Als Link-Notiz speichern?'),
                    ),
                  ),
                if (_preview != null &&
                    (_preview!.linkTitle != null ||
                        _preview!.linkThumbnailUrl != null))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _preview!.linkThumbnailUrl != null
                        ? Image.network(_preview!.linkThumbnailUrl!, width: 48)
                        : const Icon(Icons.link),
                    title: Text(_preview!.linkTitle ?? ''),
                    subtitle: Text(_preview!.linkDomain ?? ''),
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
                    unawaited(_fetchPreview(checkDup: true));
                  },
                ),
                TextButton(
                  onPressed: () {
                    unawaited(_fetchPreview(checkDup: true));
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
                onChanged: (v) => setState(() {
                  _personal = v;
                  _categoryId = null;
                }),
              ),
              Text(
                'Kategorie',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              catsAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text(
                  'Kategorien konnten nicht geladen werden: $e',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                data: (cats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          CategoryAccentChip(
                            label: 'Keine',
                            accentColor: null,
                            selected: _categoryId == null,
                            onTap: () => setState(() => _categoryId = null),
                          ),
                          const SizedBox(width: 8),
                          ...cats.map(
                            (c) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CategoryAccentChip(
                                label: '${c.icon} ${c.name}',
                                accentColor: c.color,
                                selected: _categoryId == c.id,
                                onTap: () =>
                                    setState(() => _categoryId = c.id),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _saving ? null : _openCreateNoteCategoryDialog,
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            label: const Text('Neu'),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              _settingsRow(
                title: 'Kartenfarbe',
                subtitle: null,
                trailing: _noteColor != null
                    ? CircleAvatar(backgroundColor: _noteColor, radius: 14)
                    : Icon(Icons.palette_outlined, color: theme.iconTheme.color),
                onTap: _pickColor,
              ),
              _settingsRow(
                title: 'Erinnerung',
                subtitle: _reminder == null
                    ? 'Keine'
                    : _reminder!.toLocal().toString().split('.').first,
                trailing: Icon(Icons.schedule, color: theme.iconTheme.color),
                onTap: _pickReminder,
              ),
              const SizedBox(height: 8),
              Text('Anhänge', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _showAttachMenu,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Foto hinzufügen'),
              ),
              if (visibleExisting.isNotEmpty || _pendingFiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 88 * 9 / 16 + 8,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...visibleExisting.asMap().entries.map((e) {
                        return KeyedSubtree(
                          key: ValueKey('ex-${e.value.id}'),
                          child: _buildExistingThumb(e.value, theme),
                        );
                      }),
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
          onPressed: (_saving || _sharedMediaBusy) ? null : _save,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/category_accent_chips.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_category_repository.dart';
import '../data/note_repository.dart';
import '../domain/note_category.dart';
import '../logic/note_quick_capture.dart';
import 'notes_screen.dart';

/// Set by [NoteShareIntentListener]; [NotesScreen] consumes and opens quick capture.
final pendingSharedNoteTextProvider = StateProvider<String?>((ref) => null);

/// Images/videos/files shared into the app; [NotesScreen] opens [NoteFormDialog].
final pendingSharedNoteMediaProvider =
    StateProvider<List<SharedMediaFile>?>((ref) => null);

class _QuickCaptureResult {
  final int? categoryId;
  final bool isPersonal;

  const _QuickCaptureResult({
    required this.categoryId,
    required this.isPersonal,
  });
}

String _previewRaw(String raw, {int maxLen = 160}) {
  final t = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t.length <= maxLen) return t;
  return '${t.substring(0, maxLen)}…';
}

/// Quick capture from clipboard (scope = current notes filter) or share (user picks scope).
Future<void> runQuickNoteCapture(
  WidgetRef ref,
  BuildContext context,
  String raw, {
  required bool askScope,
}) async {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return;

  if (!context.mounted) return;

  final result = await showModalBottomSheet<_QuickCaptureResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _QuickCaptureSheetBody(
      rawPreview: _previewRaw(trimmed),
      askScope: askScope,
      initialShareScope: NotesScope.family,
      fixedIsPersonal: askScope
          ? null
          : ref.read(notesScopeProvider) == NotesScope.personal,
    ),
  );

  if (result == null || !context.mounted) return;

  try {
    await ref.read(noteRepositoryProvider).createNote(
          buildQuickNotePayload(
            trimmed,
            isPersonal: result.isPersonal,
            categoryId: result.categoryId,
          ),
        );
    invalidateAllNotesScopes(ref);
    invalidateNoteCategoryCaches(ref);
    if (askScope) {
      ref.read(notesScopeProvider.notifier).state = result.isPersonal
          ? NotesScope.personal
          : NotesScope.family;
    }
    if (context.mounted) {
      showAppToast(context, message: 'Notiz angelegt', type: ToastType.success);
    }
  } on ApiException catch (e) {
    if (context.mounted) {
      showAppToast(context, message: e.message, type: ToastType.error);
    }
  }
}

class _QuickCaptureSheetBody extends ConsumerStatefulWidget {
  const _QuickCaptureSheetBody({
    required this.rawPreview,
    required this.askScope,
    required this.initialShareScope,
    required this.fixedIsPersonal,
  });

  final String rawPreview;
  final bool askScope;
  final NotesScope initialShareScope;
  final bool? fixedIsPersonal;

  @override
  ConsumerState<_QuickCaptureSheetBody> createState() =>
      _QuickCaptureSheetBodyState();
}

class _QuickCaptureSheetBodyState extends ConsumerState<_QuickCaptureSheetBody> {
  late NotesScope _shareScope;

  @override
  void initState() {
    super.initState();
    _shareScope = widget.initialShareScope;
  }

  bool get _categoriesForPersonal {
    if (widget.askScope) {
      return _shareScope == NotesScope.personal;
    }
    return widget.fixedIsPersonal ?? false;
  }

  void _pick(int? categoryId) {
    final isPersonal = widget.fixedIsPersonal ??
        (_shareScope == NotesScope.personal);
    Navigator.pop(
      context,
      _QuickCaptureResult(categoryId: categoryId, isPersonal: isPersonal),
    );
  }

  Future<void> _createCategory() async {
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
      final forPersonal = _categoriesForPersonal;
      try {
        final created =
            await ref.read(noteCategoryRepositoryProvider).createCategory({
          'name': trimmed,
          'color': hex,
          'icon': '\u{1F4DD}',
          'is_personal': forPersonal,
        });
        invalidateNoteCategoryCaches(ref);
        if (mounted) {
          showAppToast(context,
              message: 'Kategorie angelegt', type: ToastType.success);
        }
        _pick(created.id);
      } on ApiException catch (e) {
        if (mounted) {
          showAppToast(context, message: e.message, type: ToastType.error);
        }
      }
    } finally {
      name.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.65;
    final catsAsync =
        ref.watch(noteCategoriesListProvider(_categoriesForPersonal));

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxH),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  widget.askScope
                      ? 'Geteilten Inhalt speichern'
                      : 'Kategorie für neue Notiz',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (widget.askScope) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.rawPreview,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Sichtbarkeit',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                  child: SegmentedButton<NotesScope>(
                    segments: const [
                      ButtonSegment(
                        value: NotesScope.personal,
                        label: Text('Persönlich'),
                      ),
                      ButtonSegment(
                        value: NotesScope.family,
                        label: Text('Familie'),
                      ),
                    ],
                    selected: {_shareScope},
                    onSelectionChanged: (s) {
                      setState(() => _shareScope = s.first);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Text(
                    'Kategorie',
                    style: theme.textTheme.labelLarge,
                  ),
                ),
              ],
              ListTile(
                leading: const Icon(Icons.folder_off_outlined),
                title: const Text('Ohne Kategorie'),
                onTap: () => _pick(null),
              ),
              ListTile(
                leading: Icon(
                  Icons.add_circle_outline,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Neue Kategorie…'),
                onTap: _createCategory,
              ),
              catsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('$e',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
                data: (List<NoteCategory> categories) => Column(
                  children: categories
                      .map(
                        (c) => ListTile(
                          leading:
                              Text(c.icon, style: const TextStyle(fontSize: 22)),
                          title: Text(c.name),
                          onTap: () => _pick(c.id),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

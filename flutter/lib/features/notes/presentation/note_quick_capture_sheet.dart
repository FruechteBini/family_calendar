import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_category_repository.dart';
import '../data/note_repository.dart';
import '../domain/note_category.dart';
import '../logic/note_quick_capture.dart';
import 'notes_screen.dart';

/// Set by [NoteShareIntentListener]; [NotesScreen] consumes and opens quick capture.
final pendingSharedNoteTextProvider = StateProvider<String?>((ref) => null);

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

  List<NoteCategory> categories;
  try {
    categories = await ref.read(noteCategoriesListProvider.future);
  } on ApiException catch (e) {
    if (context.mounted) {
      showAppToast(context, message: e.message, type: ToastType.error);
    }
    return;
  }

  if (!context.mounted) return;

  final result = await showModalBottomSheet<_QuickCaptureResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _QuickCaptureSheetBody(
      categories: categories,
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
    ref.invalidate(noteCategoriesListProvider);
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

class _QuickCaptureSheetBody extends StatefulWidget {
  const _QuickCaptureSheetBody({
    required this.categories,
    required this.rawPreview,
    required this.askScope,
    required this.initialShareScope,
    required this.fixedIsPersonal,
  });

  final List<NoteCategory> categories;
  final String rawPreview;
  final bool askScope;
  final NotesScope initialShareScope;
  final bool? fixedIsPersonal;

  @override
  State<_QuickCaptureSheetBody> createState() => _QuickCaptureSheetBodyState();
}

class _QuickCaptureSheetBodyState extends State<_QuickCaptureSheetBody> {
  late NotesScope _shareScope;

  @override
  void initState() {
    super.initState();
    _shareScope = widget.initialShareScope;
  }

  void _pick(int? categoryId) {
    final isPersonal = widget.fixedIsPersonal ??
        (_shareScope == NotesScope.personal);
    Navigator.pop(
      context,
      _QuickCaptureResult(categoryId: categoryId, isPersonal: isPersonal),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxH = MediaQuery.sizeOf(context).height * 0.65;

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
              ...widget.categories.map(
                (c) => ListTile(
                  leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
                  title: Text(c.name),
                  onTap: () => _pick(c.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

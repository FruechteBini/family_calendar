import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_repository.dart';
import '../domain/note.dart';
import 'note_attachment_helpers.dart';
import '../../todos/presentation/todo_form_dialog.dart';

class NoteCard extends ConsumerWidget {
  final Note note;
  final VoidCallback onRefresh;
  final VoidCallback onEdit;
  final VoidCallback onOpenComments;

  const NoteCard({
    super.key,
    required this.note,
    required this.onRefresh,
    required this.onEdit,
    required this.onOpenComments,
  });

  Color? _cardTint(String? hex) {
    if (hex == null || hex.length != 7) return null;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return null;
    }
  }

  Future<void> _menu(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(noteRepositoryProvider);
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(note.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
              title: Text(note.isPinned ? 'Loslösen' : 'Anpinnen'),
              onTap: () => Navigator.pop(ctx, 'pin'),
            ),
            ListTile(
              leading: const Icon(Icons.inventory_2_outlined),
              title: Text(note.isArchived ? 'Aus Archiv holen' : 'Archivieren'),
              onTap: () => Navigator.pop(ctx, 'archive'),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Farbe wählen…'),
              onTap: () => Navigator.pop(ctx, 'color'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: const Text('Als Todo übernehmen'),
              onTap: () => Navigator.pop(ctx, 'todo'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Löschen'),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || choice == null) return;
    try {
      switch (choice) {
        case 'pin':
          await repo.togglePin(note.id);
          break;
        case 'archive':
          await repo.toggleArchive(note.id);
          break;
        case 'color':
          final c = await _pickColor(context);
          if (c == null) break; // dialog dismissed
          await repo.setColor(
            note.id,
            c == '__CLEAR__' ? null : c,
          );
          break;
        case 'todo':
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => TodoFormDialog(convertFromNote: note),
          );
          if (context.mounted && created == true) {
            showAppToast(context,
                message: 'Todo erstellt', type: ToastType.success);
          }
          break;
        case 'delete':
          final ok = await showDialog<bool>(
            context: context,
            builder: (x) => AlertDialog(
              title: const Text('Notiz löschen?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(x, false),
                    child: const Text('Abbrechen')),
                FilledButton(
                    onPressed: () => Navigator.pop(x, true),
                    child: const Text('Löschen')),
              ],
            ),
          );
          if (ok == true) await repo.deleteNote(note.id);
          break;
      }
      onRefresh();
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  /// Returns null if dismissed, '__CLEAR__' to remove color, or a hex string.
  Future<String?> _pickColor(BuildContext context) async {
    const presets = [
      '#FFF9C4',
      '#FFCCBC',
      '#C8E6C9',
      '#BBDEFB',
      '#E1BEE7',
      '#FFFFFF',
    ];
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kartenfarbe'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('Keine'),
              onPressed: () => Navigator.pop(ctx, '__CLEAR__'),
            ),
            ...presets.map(
              (h) => InkWell(
                onTap: () => Navigator.pop(ctx, h),
                child: CircleAvatar(
                  backgroundColor: _cardTint(h),
                  radius: 20,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final u = Uri.tryParse(url);
    if (u != null && await canLaunchUrl(u)) {
      await launchUrl(u, mode: LaunchMode.externalApplication);
    }
  }

  /// Bild- und Video-Anhänge wie Link-Vorschau (16:9-Kacheln, horizontal scrollbar).
  Widget? _mediaAttachmentStrip(BuildContext context, WidgetRef ref, Note note) {
    final media = note.attachments
        .where((a) => noteAttachmentIsImage(a) || noteAttachmentIsVideo(a))
        .toList();
    if (media.isEmpty) return null;

    final theme = Theme.of(context);
    final screenW = MediaQuery.sizeOf(context).width;
    final thumbW = (screenW - 40).clamp(200.0, 360.0);
    final thumbH = thumbW * 9 / 16;
    final headers = noteImageRequestHeaders(ref);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SizedBox(
        height: thumbH,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: media.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final a = media[i];
            final url = noteAttachmentFullUrl(ref, a);
            final isImg = noteAttachmentIsImage(a);
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: thumbW,
                height: thumbH,
                child: isImg
                    ? CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        httpHeaders: headers,
                        placeholder: (_, __) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => _attachmentVideoPlaceholder(
                          theme,
                          a.filename,
                        ),
                      )
                    : _attachmentVideoPlaceholder(theme, a.filename),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _attachmentVideoPlaceholder(ThemeData theme, String filename) {
    return ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Icon(
              Icons.play_circle_outline,
              size: 48,
              color: theme.colorScheme.primary.withValues(alpha: 0.85),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Text(
              filename,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tint = _cardTint(note.color);
    final borderRadius = BorderRadius.circular(12);

    final attachmentStrip = _mediaAttachmentStrip(context, ref, note);

    Widget body;
    switch (note.type) {
      case NoteType.link:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (note.linkThumbnailUrl != null &&
                note.linkThumbnailUrl!.isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: note.linkThumbnailUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.link),
                    ),
                  ),
                ),
              ),
            ListTile(
              onTap: note.url != null ? () => _openUrl(note.url!) : null,
              title: Text(
                note.linkTitle ?? note.displayTitle,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.linkDomain != null)
                    Text(
                      note.linkDomain!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  if (note.linkDescription != null &&
                      note.linkDescription!.isNotEmpty)
                    Text(
                      note.linkDescription!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (attachmentStrip != null) attachmentStrip,
          ],
        );
        break;
      case NoteType.checklist:
        final items = note.checklistItems ?? [];
        final done = items.where((e) => e.checked).length;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (attachmentStrip != null) attachmentStrip,
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.displayTitle, style: theme.textTheme.titleMedium),
                  if (items.isNotEmpty)
                    Text(
                      '$done / ${items.length} erledigt',
                      style: theme.textTheme.labelSmall,
                    ),
                  const SizedBox(height: 8),
                  ...items.asMap().entries.map((e) {
                    final i = e.key;
                    final it = e.value;
                    return CheckboxListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: it.checked,
                      title: Text(it.text,
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                      onChanged: (v) async {
                        if (v == null) return;
                        final next = List<ChecklistItem>.from(items);
                        next[i] = ChecklistItem(text: it.text, checked: v);
                        try {
                          await ref.read(noteRepositoryProvider).updateNote(
                                note.id,
                                {
                                  'checklist_items': next
                                      .map((x) => x.toJson())
                                      .toList(),
                                },
                              );
                          onRefresh();
                        } on ApiException catch (ex) {
                          if (context.mounted) {
                            showAppToast(context,
                                message: ex.message, type: ToastType.error);
                          }
                        }
                      },
                    );
                  }),
                ],
              ),
            ),
          ],
        );
        break;
      case NoteType.text:
        final md = note.content ?? '';
        final preview = md.length > 400 ? '${md.substring(0, 400)}…' : md;
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (attachmentStrip != null) attachmentStrip,
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(note.displayTitle, style: theme.textTheme.titleMedium),
                  if (md.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    MarkdownBody(
                      data: preview,
                      shrinkWrap: true,
                      styleSheet: MarkdownStyleSheet(
                        p: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
    }

    return Card(
      elevation: note.isPinned ? 2 : 0,
      color: tint ?? theme.colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: borderRadius),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onEdit,
        onLongPress: () => _menu(context, ref),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            body,
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Row(
                children: [
                  if (note.isPinned)
                    Icon(Icons.push_pin,
                        size: 16, color: theme.colorScheme.primary),
                  if (note.reminderAt != null)
                    Icon(Icons.alarm,
                        size: 16, color: theme.colorScheme.tertiary),
                  ...note.tags.take(4).map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Chip(
                            label: Text(t.name,
                                style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelPadding:
                                const EdgeInsets.symmetric(horizontal: 6),
                          ),
                        ),
                      ),
                  const Spacer(),
                  if (note.comments.isNotEmpty)
                    TextButton.icon(
                      onPressed: onOpenComments,
                      icon: const Icon(Icons.chat_bubble_outline, size: 18),
                      label: Text('${note.comments.length}'),
                    ),
                  if (note.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.attach_file,
                          size: 18, color: theme.hintColor),
                    ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => _menu(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/sync/mutation_refresh.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../notifications/domain/notification_level.dart';
import '../../notifications/presentation/widgets/notification_level_picker.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import '../domain/event_recurrence.dart';
import 'calendar_screen_real.dart';
import 'event_form_dialog.dart';

typedef EventDetailKey = ({int id, DateTime? occurrenceStart});

final eventDetailProvider =
    FutureProvider.family<Event, EventDetailKey>((ref, key) async {
  return ref.watch(eventRepositoryProvider).getEvent(
        key.id,
        occurrenceStart: key.occurrenceStart,
      );
});

class EventDetailScreen extends ConsumerWidget {
  final int eventId;
  final DateTime? occurrenceStart;

  const EventDetailScreen({
    super.key,
    required this.eventId,
    this.occurrenceStart,
  });

  Future<void> _edit(BuildContext context, WidgetRef ref, Event event) async {
    final outcome = await showDialog<EventFormDialogOutcome?>(
      context: context,
      builder: (_) => EventFormDialog(event: event, initialDate: event.startTime),
    );
    if (outcome == EventFormDialogOutcome.deleted) {
      refreshAfterMutation(ref);
      ref.invalidate(monthEventsProvider);
      if (context.mounted) context.pop();
      return;
    }
    if (outcome == EventFormDialogOutcome.saved) {
      refreshAfterMutation(ref);
      ref.invalidate(
        eventDetailProvider(
          (id: eventId, occurrenceStart: occurrenceStart),
        ),
      );
      ref.invalidate(monthEventsProvider);
      if (context.mounted) {
        showAppToast(context, message: 'Gespeichert', type: ToastType.success);
      }
    }
  }

  static String? _notificationLevelLabel(int? id, List<NotificationLevel> levels) {
    if (id == null) return null;
    for (final l in levels) {
      if (l.id == id) return l.name;
    }
    return null;
  }

  Future<void> _deleteFromDetail(BuildContext context, WidgetRef ref, Event e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Termin löschen?'),
        content: Text('Soll „${e.title}“ wirklich gelöscht werden?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;
    try {
      await ref.read(eventRepositoryProvider).deleteEvent(e.id);
      refreshAfterMutation(ref);
      ref.invalidate(monthEventsProvider);
      if (context.mounted) context.pop();
    } on ApiException catch (err) {
      if (context.mounted) {
        showAppToast(context, message: err.message, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailKey = (id: eventId, occurrenceStart: occurrenceStart);
    final eventAsync = ref.watch(eventDetailProvider(detailKey));
    final levelsAsync = ref.watch(notificationLevelsListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Termin'),
        actions: [
          eventAsync.maybeWhen(
            data: (e) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Löschen',
                  icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    padding: const EdgeInsets.all(14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _deleteFromDetail(context, ref, e),
                ),
                IconButton(
                  tooltip: 'Bearbeiten',
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 28,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    padding: const EdgeInsets.all(14),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => _edit(context, ref, e),
                ),
              ],
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.event_busy_outlined,
          title: 'Termin konnte nicht geladen werden',
          subtitle: err is ApiException ? err.message : err.toString(),
        ),
        data: (e) {
          final levels = levelsAsync.valueOrNull ?? [];
          final pushLabel = _notificationLevelLabel(e.notificationLevelId, levels);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _DetailSection(
                icon: Icons.title,
                label: 'Titel',
                child: Text(
                  e.title,
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              if (e.description != null && e.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailSection(
                  icon: Icons.notes_outlined,
                  label: 'Beschreibung',
                  child: Text(e.description!, style: theme.textTheme.bodyMedium),
                ),
              ],
              const SizedBox(height: 12),
              _DetailSection(
                icon: Icons.today_outlined,
                label: 'Ganztägig',
                child: Text(e.allDay ? 'Ja' : 'Nein', style: theme.textTheme.bodyMedium),
              ),
              const SizedBox(height: 12),
              _DetailSection(
                icon: Icons.calendar_today_outlined,
                label: 'Beginn',
                child: Text(
                  e.allDay
                      ? AppDateUtils.formatDate(e.startTime)
                      : '${AppDateUtils.formatDate(e.startTime)} · ${AppDateUtils.formatTime(e.startTime)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              _DetailSection(
                icon: Icons.event_outlined,
                label: 'Ende',
                child: Text(
                  e.allDay
                      ? AppDateUtils.formatDate(e.endTime)
                      : '${AppDateUtils.formatDate(e.endTime)} · ${AppDateUtils.formatTime(e.endTime)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              _DetailSection(
                icon: Icons.folder_outlined,
                label: 'Kategorie',
                child: Text(
                  e.categoryName ?? 'Keine Kategorie',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
              _DetailSection(
                icon: Icons.palette_outlined,
                label: 'Farbe in der Ansicht',
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: _detailEventPreviewColor(context, e),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        e.color != null
                            ? 'Eigene Terminfarbe (${e.color})'
                            : 'Kategoriefarbe${e.categoryColor != null ? '' : ' / Standard'}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _DetailSection(
                icon: Icons.notifications_outlined,
                label: 'Push-Dringlichkeit',
                child: Text(
                  levelsAsync.isLoading
                      ? '…'
                      : (pushLabel ??
                          (e.notificationLevelId == null ? 'Keine' : 'Unbekannte Stufe')),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              if (e.recurrenceRules.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailSection(
                  icon: Icons.repeat,
                  label: 'Wiederholung',
                  child: Text(
                    _formatRecurrenceSummary(e.recurrenceRules),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
              if (e.members.isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailSection(
                  icon: Icons.people_outline,
                  label: 'Mitglieder',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: e.members
                        .map(
                          (m) => Chip(
                            avatar: CircleAvatar(
                              child: Text(
                                m.emoji ??
                                    (m.name.isNotEmpty ? m.name[0].toUpperCase() : '?'),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            label: Text(m.name),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

Color _detailEventPreviewColor(BuildContext context, Event e) {
  final hex = e.displayColorHex;
  if (hex == null || hex.isEmpty) {
    return Theme.of(context).colorScheme.primary;
  }
  final h = hex.replaceAll('#', '').trim();
  if (h.length == 6) {
    try {
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {}
  }
  return Theme.of(context).colorScheme.primary;
}

String _formatRecurrenceSummary(List<EventRecurrenceRule> rules) {
  if (rules.isEmpty) return '';
  const freq = {
    'daily': 'Täglich',
    'weekly': 'Wöchentlich',
    'monthly': 'Monatlich',
    'yearly': 'Jährlich',
  };
  const dayNames = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  final parts = <String>[];
  for (final r in rules) {
    final f = freq[r.frequency] ?? r.frequency;
    final every = r.interval > 1 ? 'alle ${r.interval} ' : '';
    var line = '$every$f';
    if (r.frequency == 'weekly' && r.byWeekday != null && r.byWeekday!.isNotEmpty) {
      final names = r.byWeekday!
          .map((d) => (d >= 1 && d <= 7) ? dayNames[d - 1] : '$d')
          .join(', ');
      line += ' ($names)';
    }
    if (r.until != null) {
      line += ' bis ${AppDateUtils.formatDate(r.until!)}';
    }
    if (r.count != null) {
      line += ', ${r.count}×';
    }
    parts.add(line);
  }
  return parts.join(' · ');
}

class _DetailSection extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _DetailSection({
    required this.icon,
    required this.label,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

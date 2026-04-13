import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/main_tab_swipe_scope.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../core/sync/sync_service.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import 'event_form_dialog.dart';

final calendarMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, 1);
});

final calendarSelectedDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

final monthEventsProvider = FutureProvider.family<List<Event>, DateTime>((ref, month) {
  // Recompute after out-of-band mutations (e.g. voice command created event).
  ref.watch(syncTickProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
  return ref.watch(eventRepositoryProvider).getEvents(startDate: start, endDate: end);
});

Future<void> _showCalendarMonthYearPicker({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime month,
}) async {
  final selected = ref.read(calendarSelectedDayProvider);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final initialDay = (selected.year == month.year && selected.month == month.month)
      ? selected.day.clamp(1, daysInMonth)
      : 1;
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(month.year, month.month, initialDay),
    firstDate: DateTime(2000, 1, 1),
    lastDate: DateTime(2100, 12, 31),
    locale: const Locale('de', 'DE'),
    helpText: 'Monat und Jahr wählen',
  );
  if (picked == null || !context.mounted) return;
  ref.read(calendarMonthProvider.notifier).state = DateTime(picked.year, picked.month, 1);
  ref.read(calendarSelectedDayProvider.notifier).state = picked;
}

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(calendarMonthProvider);
    final selected = ref.watch(calendarSelectedDayProvider);
    final eventsAsync = ref.watch(monthEventsProvider(month));

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final outcome = await showDialog<EventFormDialogOutcome?>(
            context: context,
            builder: (_) => EventFormDialog(initialDate: selected),
          );
          if (outcome == EventFormDialogOutcome.saved) {
            ref.invalidate(monthEventsProvider(month));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: MainTabSwipeScope(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(monthEventsProvider(month));
              await ref.read(monthEventsProvider(month).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppColors.spacing4),
                  child: _MonthHeader(month: month),
                ),
              ),
              SliverToBoxAdapter(
                child: eventsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppColors.spacing6),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'Kalender konnte nicht geladen werden',
                    subtitle: err is ApiException ? err.message : err.toString(),
                  ),
                  data: (events) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing4),
                    child: _MonthGrid(
                      month: month,
                      selected: selected,
                      events: events,
                      onSelect: (d) => ref.read(calendarSelectedDayProvider.notifier).state = d,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppColors.spacing4)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing4),
                  child: Text(
                    _formatSelectedTitle(selected),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              eventsAsync.when(
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (events) {
                  final dayEvents = _eventsForDay(events, selected);
                  if (dayEvents.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.all(AppColors.spacing6),
                        child: EmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'Keine Termine',
                          subtitle: 'Für diesen Tag sind keine Termine eingetragen.',
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppColors.spacing4, AppColors.spacing3, AppColors.spacing4, 120),
                    sliver: SliverList.separated(
                      itemCount: dayEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _EventTile(
                        event: dayEvents[i],
                        onTap: () {
                          context.push('/events/${dayEvents[i].id}');
                        },
                      ),
                    ),
                  );
                },
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatSelectedTitle(DateTime d) {
    const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final wd = names[(d.weekday - 1).clamp(0, 6)];
    return '$wd, ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static List<Event> _eventsForDay(List<Event> events, DateTime day) {
    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    return events.where((e) => sameDay(e.startTime, day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}

class _MonthHeader extends ConsumerWidget {
  final DateTime month;
  const _MonthHeader({required this.month});

  static final _monthYearFormat = DateFormat('MMMM yyyy', 'de_DE');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = _monthYearFormat.format(month);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            final prev = DateTime(month.year, month.month - 1, 1);
            ref.read(calendarMonthProvider.notifier).state = prev;
          },
        ),
        Expanded(
          child: Tooltip(
            message: 'Monat und Jahr wählen',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showCalendarMonthYearPicker(context: context, ref: ref, month: month),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            final next = DateTime(month.year, month.month + 1, 1);
            ref.read(calendarMonthProvider.notifier).state = next;
          },
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final List<Event> events;
  final ValueChanged<DateTime> onSelect;

  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.events,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final firstWeekday = first.weekday; // 1=Mon
    final start = first.subtract(Duration(days: firstWeekday - 1));
    final days = List.generate(42, (i) => start.add(Duration(days: i)));

    bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
    final byDay = <String, int>{};
    for (final e in events) {
      final k = '${e.startTime.year}-${e.startTime.month}-${e.startTime.day}';
      byDay[k] = (byDay[k] ?? 0) + 1;
    }

    const weekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

    return Column(
      children: [
        Row(
          children: weekdayLabels
              .map((w) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(w, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ))
              .toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.1,
          ),
          itemCount: days.length,
          itemBuilder: (_, i) {
            final d = days[i];
            final inMonth = d.month == month.month;
            final isSelected = sameDay(d, selected);
            final k = '${d.year}-${d.month}-${d.day}';
            final count = byDay[k] ?? 0;
            final cs = Theme.of(context).colorScheme;

            return GestureDetector(
              onTap: () => onSelect(DateTime(d.year, d.month, d.day)),
              child: Container(
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primaryContainer : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${d.day}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: inMonth ? AppColors.onSurface : AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                    ),
                    const SizedBox(height: 3),
                    if (count > 0)
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected ? cs.primary : AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _EventTile extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final time = event.allDay
        ? 'Ganztags'
        : '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';
    final color =
        _parseHex(event.categoryColor) ?? Theme.of(context).colorScheme.primary;

    return Card(
      color: AppColors.surfaceContainerHigh,
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 10,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(event.title),
        subtitle: Text(time),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final h = hex.replaceAll('#', '').trim();
    if (h.length == 6) {
      return Color(int.parse('FF$h', radix: 16));
    }
    if (h.length == 8) {
      return Color(int.parse(h, radix: 16));
    }
    return null;
  }
}


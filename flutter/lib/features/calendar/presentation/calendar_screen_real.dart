import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/main_tab_swipe_scope.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../core/sync/mutation_refresh.dart';
import '../../../core/sync/sync_service.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import 'event_form_dialog.dart';

DateTime _calendarDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

bool _sameCalendarDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Montag der Kalenderwoche, die den 1. des Monats von [month] enthält.
DateTime _monthGridStart(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  return first.subtract(Duration(days: first.weekday - 1));
}

/// Anzahl Mo–So-Zeilen, um alle Tage von [month] im Raster anzuzeigen (4–6).
int _monthWeekRowCount(DateTime month) {
  final gridStart = _monthGridStart(month);
  final lastOfMonth = DateTime(month.year, month.month + 1, 0);
  final daysInGrid = lastOfMonth.difference(gridStart).inDays + 1;
  return (daysInGrid / 7).ceil();
}

/// Inclusive calendar-day range for an event (local dates).
({DateTime start, DateTime end}) _eventDayRange(Event e) {
  var s = _calendarDay(e.startTime);
  var t = _calendarDay(e.endTime);
  if (t.isBefore(s)) t = s;
  return (start: s, end: t);
}

bool _eventIsMultiDay(Event e) {
  final r = _eventDayRange(e);
  return r.end.isAfter(r.start);
}

int _isoWeekNumberFromMonday(DateTime monday) {
  final thu = monday.add(const Duration(days: 3));
  final jan1 = DateTime(thu.year, 1, 1);
  final firstThu = jan1.add(
    Duration(days: (DateTime.thursday - jan1.weekday + 7) % 7),
  );
  return 1 + thu.difference(firstThu).inDays ~/ 7;
}

Color? _parseEventHex(String? hex) {
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

Color _contrastOnBackground(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.55 ? const Color(0xFF1A1C1E) : Colors.white;
}

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
  final gridStart = _monthGridStart(month);
  final weekCount = _monthWeekRowCount(month);
  final gridEnd = gridStart.add(Duration(days: weekCount * 7 - 1));
  final end = DateTime(gridEnd.year, gridEnd.month, gridEnd.day, 23, 59, 59);
  return ref.watch(eventRepositoryProvider).getEvents(startDate: gridStart, endDate: end);
});

void _handleCalendarDayTap({
  required BuildContext context,
  required WidgetRef ref,
  required DateTime tappedDay,
  required List<Event> events,
}) {
  final norm = DateTime(tappedDay.year, tappedDay.month, tappedDay.day);
  final sel = ref.read(calendarSelectedDayProvider);
  if (_sameCalendarDay(sel, norm)) {
    _showSelectedDayBottomSheet(
      context: context,
      day: norm,
      events: events,
    );
  } else {
    ref.read(calendarSelectedDayProvider.notifier).state = norm;
  }
}

Future<void> _showSelectedDayBottomSheet({
  required BuildContext context,
  required DateTime day,
  required List<Event> events,
}) async {
  final routerContext = context;
  final selected = DateTime(day.year, day.month, day.day);
  final dayEvents = CalendarScreen._eventsForDay(events, selected);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.22,
        maxChildSize: 0.92,
        builder: (dragContext, scrollController) {
          final theme = Theme.of(dragContext);
          return Material(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      ScreenHeader.horizontalPadding,
                      4,
                      ScreenHeader.horizontalPadding,
                      AppColors.spacing2,
                    ),
                    child: Text(
                      CalendarScreen._formatSelectedTitle(selected),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (dayEvents.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.all(AppColors.spacing6),
                      child: EmptyState(
                        icon: Icons.event_available_outlined,
                        title: 'Keine Termine',
                        subtitle:
                            'Für diesen Tag sind keine Termine eingetragen.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      ScreenHeader.horizontalPadding,
                      AppColors.spacing2,
                      ScreenHeader.horizontalPadding,
                      120,
                    ),
                    sliver: SliverList.separated(
                      itemCount: dayEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _EventTile(
                        event: dayEvents[i],
                        onTap: () {
                          final loc = dayEvents[i].detailLocation;
                          Navigator.pop(sheetContext);
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (routerContext.mounted) {
                              routerContext.push(loc);
                            }
                          });
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Passe den ausgewählten Tag an, wenn der Monat gewechselt wurde (z. B. 31. → 30.).
void _clampSelectedDayToMonth(WidgetRef ref, DateTime newMonthFirst) {
  final sel = ref.read(calendarSelectedDayProvider);
  if (sel.year == newMonthFirst.year && sel.month == newMonthFirst.month) {
    return;
  }
  final daysIn = DateTime(newMonthFirst.year, newMonthFirst.month + 1, 0).day;
  final day = sel.day.clamp(1, daysIn);
  ref.read(calendarSelectedDayProvider.notifier).state =
      DateTime(newMonthFirst.year, newMonthFirst.month, day);
}

void _onCalendarMonthHorizontalSwipe({
  required WidgetRef ref,
  required DateTime month,
  required DragEndDetails details,
}) {
  final v = details.primaryVelocity;
  if (v == null) return;
  const threshold = 400;
  if (v > threshold) {
    final prev = DateTime(month.year, month.month - 1, 1);
    ref.read(calendarMonthProvider.notifier).state = prev;
    _clampSelectedDayToMonth(ref, prev);
  } else if (v < -threshold) {
    final next = DateTime(month.year, month.month + 1, 1);
    ref.read(calendarMonthProvider.notifier).state = next;
    _clampSelectedDayToMonth(ref, next);
  }
}

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

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();

  static String _formatSelectedTitle(DateTime d) {
    const names = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final wd = names[(d.weekday - 1).clamp(0, 6)];
    return '$wd, ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  static List<Event> _eventsForDay(List<Event> events, DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return events.where((e) {
      final r = _eventDayRange(e);
      return !r.end.isBefore(d) && !r.start.isAfter(d);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final GlobalKey _todayWeekRowKey = GlobalKey();
  bool _pendingScrollToTodayWeek = true;

  @override
  void initState() {
    super.initState();
    _pendingScrollToTodayWeek = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final month = ref.read(calendarMonthProvider);
      final events = ref.read(monthEventsProvider(month));
      if (events is AsyncData<List<Event>>) {
        _scheduleScrollToTodayWeekIfNeeded();
      }
    });
  }

  void _scheduleScrollToTodayWeekIfNeeded() {
    final month = ref.read(calendarMonthProvider);
    final now = DateTime.now();
    if (month.year != now.year || month.month != now.month) {
      return;
    }
    if (!_pendingScrollToTodayWeek) return;

    void attempt(int remaining) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final m = ref.read(calendarMonthProvider);
        final n = DateTime.now();
        if (m.year != n.year || m.month != n.month) return;

        final ctx = _todayWeekRowKey.currentContext;
        if (ctx != null) {
          _pendingScrollToTodayWeek = false;
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.0,
            duration: Duration.zero,
            curve: Curves.linear,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
          return;
        }
        if (remaining > 0) {
          attempt(remaining - 1);
        }
      });
    }

    attempt(4);
  }

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(calendarMonthProvider);
    final selected = ref.watch(calendarSelectedDayProvider);
    final eventsAsync = ref.watch(monthEventsProvider(month));

    ref.listen<DateTime>(calendarMonthProvider, (prev, next) {
      _pendingScrollToTodayWeek = true;
    });

    ref.listen<AsyncValue<List<Event>>>(
      monthEventsProvider(month),
      (prev, next) {
        if (next is AsyncData<List<Event>>) {
          _scheduleScrollToTodayWeekIfNeeded();
        }
      },
    );

    final now = DateTime.now();
    final todayWeekRowKey =
        month.year == now.year && month.month == now.month ? _todayWeekRowKey : null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final outcome = await showDialog<EventFormDialogOutcome?>(
            context: context,
            builder: (_) => EventFormDialog(initialDate: selected),
          );
          if (outcome == EventFormDialogOutcome.saved ||
              outcome == EventFormDialogOutcome.deleted) {
            refreshAfterMutation(ref);
            ref.invalidate(monthEventsProvider(month));
          }
        },
        child: const Icon(Icons.add),
      ),
      body: MainTabSwipeScope(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(monthEventsProvider(month));
              await ref.read(monthEventsProvider(month).future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverToBoxAdapter(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragEnd: (d) => _onCalendarMonthHorizontalSwipe(
                    ref: ref,
                    month: month,
                    details: d,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: ScreenHeader.padding(bottom: AppColors.spacing2),
                        child: _MonthHeader(month: month),
                      ),
                      eventsAsync.when(
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: ScreenHeader.horizontalPadding,
                          ),
                          child: _DenseMonthGrid(
                            month: month,
                            selected: selected,
                            events: events,
                            todayWeekRowKey: todayWeekRowKey,
                            onSelect: (d) => _handleCalendarDayTap(
                              context: context,
                              ref: ref,
                              tappedDay: d,
                              events: events,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppColors.spacing2)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ScreenHeader.horizontalPadding),
                  child: Text(
                    CalendarScreen._formatSelectedTitle(selected),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              eventsAsync.when(
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
                data: (events) {
                  final dayEvents = CalendarScreen._eventsForDay(events, selected);
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
                    padding: const EdgeInsets.fromLTRB(ScreenHeader.horizontalPadding, AppColors.spacing2, ScreenHeader.horizontalPadding, 120),
                    sliver: SliverList.separated(
                      itemCount: dayEvents.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => _EventTile(
                        event: dayEvents[i],
                        onTap: () {
                          context.push(dayEvents[i].detailLocation);
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
       );
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
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left, size: 22),
          onPressed: () {
            final prev = DateTime(month.year, month.month - 1, 1);
            ref.read(calendarMonthProvider.notifier).state = prev;
            _clampSelectedDayToMonth(ref, prev);
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
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right, size: 22),
          onPressed: () {
            final next = DateTime(month.year, month.month + 1, 1);
            ref.read(calendarMonthProvider.notifier).state = next;
            _clampSelectedDayToMonth(ref, next);
          },
        ),
      ],
    );
  }
}

class _SpanClip {
  final Event event;
  final int startCol;
  final int endCol;
  int lane = 0;

  _SpanClip({
    required this.event,
    required this.startCol,
    required this.endCol,
  });
}

GlobalKey? _weekRowKeyIfToday(
  GlobalKey? todayWeekRowKey,
  DateTime todayNorm,
  DateTime gridStart,
  int wi,
) {
  if (todayWeekRowKey == null) return null;
  final ws = gridStart.add(Duration(days: wi * 7));
  final we = ws.add(const Duration(days: 6));
  if (todayNorm.isBefore(ws) || todayNorm.isAfter(we)) return null;
  return todayWeekRowKey;
}

class _DenseMonthGrid extends StatelessWidget {
  final DateTime month;
  final DateTime selected;
  final List<Event> events;
  final GlobalKey? todayWeekRowKey;
  final ValueChanged<DateTime> onSelect;

  const _DenseMonthGrid({
    required this.month,
    required this.selected,
    required this.events,
    required this.onSelect,
    this.todayWeekRowKey,
  });

  static const _weekdayLabels = ['Mo.', 'Di.', 'Mi.', 'Do.', 'Fr.', 'Sa.', 'So.'];
  static const _dayNumH = 22.0;
  /// Zeilenhöhe für Mehrtages-Balken / Eintages-Chips (2 Textzeilen).
  static const _barH = 30.0;
  static const _barGap = 2.0;
  static const _chipH = 30.0;
  static const _maxSpanLanes = 5;
  static const _maxSingleChips = 4;
  static const _eventTitleMaxLines = 2;
  static const _eventTitleFontSize = 10.5;

  @override
  Widget build(BuildContext context) {
    final gridStart = _monthGridStart(month);
    final weekCount = _monthWeekRowCount(month);
    final dividerColor = Theme.of(context).colorScheme.outlineVariant
        .withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.45 : 0.65);

    final todayNorm = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const SizedBox(width: 28),
            ..._weekdayLabels.map(
              (w) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
        for (var wi = 0; wi < weekCount; wi++) ...[
          if (wi > 0)
            Divider(
              height: 1,
              thickness: 1,
              color: dividerColor,
            ),
          Padding(
            key: _weekRowKeyIfToday(todayWeekRowKey, todayNorm, gridStart, wi),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _DenseWeekRow(
              weekStart: gridStart.add(Duration(days: wi * 7)),
              month: month,
              selected: selected,
              events: events,
              weekLabel:
                  '${_isoWeekNumberFromMonday(gridStart.add(Duration(days: wi * 7)))}',
              onSelect: onSelect,
              dayNumH: _dayNumH,
              barH: _barH,
              barGap: _barGap,
              chipH: _chipH,
              maxSpanLanes: _maxSpanLanes,
              maxSingleChips: _maxSingleChips,
              eventTitleMaxLines: _eventTitleMaxLines,
              eventTitleFontSize: _eventTitleFontSize,
            ),
          ),
        ],
      ],
    );
  }
}

class _DenseWeekRow extends StatelessWidget {
  final DateTime weekStart;
  final DateTime month;
  final DateTime selected;
  final List<Event> events;
  final String weekLabel;
  final ValueChanged<DateTime> onSelect;
  final double dayNumH;
  final double barH;
  final double barGap;
  final double chipH;
  final int maxSpanLanes;
  final int maxSingleChips;
  final int eventTitleMaxLines;
  final double eventTitleFontSize;

  const _DenseWeekRow({
    required this.weekStart,
    required this.month,
    required this.selected,
    required this.events,
    required this.weekLabel,
    required this.onSelect,
    required this.dayNumH,
    required this.barH,
    required this.barGap,
    required this.chipH,
    required this.maxSpanLanes,
    required this.maxSingleChips,
    required this.eventTitleMaxLines,
    required this.eventTitleFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));
    final weekEnd = weekDays[6];

    final multiCandidates = events.where((e) {
      if (!_eventIsMultiDay(e)) return false;
      final r = _eventDayRange(e);
      return !r.end.isBefore(weekStart) && !r.start.isAfter(weekEnd);
    }).toList();

    final clips = <_SpanClip>[];
    for (final e in multiCandidates) {
      final r = _eventDayRange(e);
      final visStart = r.start.isBefore(weekStart) ? weekStart : r.start;
      final visEnd = r.end.isAfter(weekEnd) ? weekEnd : r.end;
      final startCol = visStart.difference(weekStart).inDays.clamp(0, 6);
      final endCol = visEnd.difference(weekStart).inDays.clamp(0, 6);
      if (startCol <= endCol) {
        clips.add(_SpanClip(event: e, startCol: startCol, endCol: endCol));
      }
    }

    clips.sort((a, b) {
      final c = a.startCol.compareTo(b.startCol);
      if (c != 0) return c;
      return (b.endCol - b.startCol).compareTo(a.endCol - a.startCol);
    });

    final laneMaxEnd = <int>[];
    for (final clip in clips) {
      var assigned = -1;
      for (var i = 0; i < laneMaxEnd.length; i++) {
        if (laneMaxEnd[i] < clip.startCol) {
          assigned = i;
          break;
        }
      }
      if (assigned < 0) {
        assigned = laneMaxEnd.length;
        laneMaxEnd.add(clip.endCol);
      } else {
        laneMaxEnd[assigned] = clip.endCol;
      }
      clip.lane = assigned;
    }

    final singleByDay = List<List<Event>>.generate(7, (ci) {
      final d = weekDays[ci];
      return events
          .where((e) =>
              !_eventIsMultiDay(e) && _sameCalendarDay(e.startTime, d))
          .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));
    });

    final visibleClips =
        clips.where((c) => c.lane < maxSpanLanes).toList();

    final blockedByMulti = List.generate(7, (_) => <int>{});
    for (final clip in visibleClips) {
      for (var col = clip.startCol; col <= clip.endCol; col++) {
        blockedByMulti[col].add(clip.lane);
      }
    }

    final singleAtRow = List.generate(7, (_) => <int, Event>{});
    for (var ci = 0; ci < 7; ci++) {
      final list = singleByDay[ci];
      final show =
          list.length > maxSingleChips ? maxSingleChips : list.length;
      var r = 0;
      for (var i = 0; i < show; i++) {
        while (blockedByMulti[ci].contains(r) ||
            singleAtRow[ci].containsKey(r)) {
          r++;
        }
        singleAtRow[ci][r] = list[i];
        r++;
      }
    }

    var maxR = -1;
    for (final clip in visibleClips) {
      if (clip.lane > maxR) maxR = clip.lane;
    }
    for (var ci = 0; ci < 7; ci++) {
      for (final r in singleAtRow[ci].keys) {
        if (r > maxR) maxR = r;
      }
      for (final r in blockedByMulti[ci]) {
        if (r > maxR) maxR = r;
      }
    }

    final eventRows = maxR + 1;
    const extraHintH = 12.0;
    final anyExtra =
        singleByDay.any((list) => list.length > maxSingleChips);
    final eventRowH = barH > chipH ? barH : chipH;

    var eventBandH = 0.0;
    if (eventRows > 0) {
      eventBandH = eventRows * (eventRowH + barGap) - barGap;
    }
    var contentH = eventBandH;
    if (anyExtra && eventRows > 0) {
      contentH += barGap + extraHintH;
    } else if (anyExtra && eventRows == 0) {
      contentH = extraHintH;
    }

    final today = DateTime.now();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final totalH = dayNumH + contentH;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              weekLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                fontSize: 10,
              ),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellW = constraints.maxWidth / 7;
              return SizedBox(
                height: totalH,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Layer 1 (bottom): 7 full-height tap targets
                    Row(
                      children: List.generate(7, (ci) {
                        final d = weekDays[ci];
                        final isSelected = _sameCalendarDay(d, selected);
                        return Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                onSelect(DateTime(d.year, d.month, d.day)),
                            child: Container(
                              height: totalH,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primaryContainer
                                        .withValues(alpha: 0.55)
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    // Layer 2 (top): all visuals, ignore pointer
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _WeekRowVisuals(
                          weekDays: weekDays,
                          month: month,
                          selected: selected,
                          today: today,
                          theme: theme,
                          cs: cs,
                          dayNumH: dayNumH,
                          cellW: cellW,
                          contentH: contentH,
                          eventRowH: eventRowH,
                          barGap: barGap,
                          eventBandH: eventBandH,
                          eventRows: eventRows,
                          visibleClips: visibleClips,
                          singleAtRow: singleAtRow,
                          singleByDay: singleByDay,
                          maxSingleChips: maxSingleChips,
                          anyExtra: anyExtra,
                          eventTitleMaxLines: eventTitleMaxLines,
                          eventTitleFontSize: eventTitleFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Pure visual layer for a week row — no hit testing.
class _WeekRowVisuals extends StatelessWidget {
  final List<DateTime> weekDays;
  final DateTime month;
  final DateTime selected;
  final DateTime today;
  final ThemeData theme;
  final ColorScheme cs;
  final double dayNumH;
  final double cellW;
  final double contentH;
  final double eventRowH;
  final double barGap;
  final double eventBandH;
  final int eventRows;
  final List<_SpanClip> visibleClips;
  final List<Map<int, Event>> singleAtRow;
  final List<List<Event>> singleByDay;
  final int maxSingleChips;
  final bool anyExtra;
  final int eventTitleMaxLines;
  final double eventTitleFontSize;

  const _WeekRowVisuals({
    required this.weekDays,
    required this.month,
    required this.selected,
    required this.today,
    required this.theme,
    required this.cs,
    required this.dayNumH,
    required this.cellW,
    required this.contentH,
    required this.eventRowH,
    required this.barGap,
    required this.eventBandH,
    required this.eventRows,
    required this.visibleClips,
    required this.singleAtRow,
    required this.singleByDay,
    required this.maxSingleChips,
    required this.anyExtra,
    required this.eventTitleMaxLines,
    required this.eventTitleFontSize,
  });

  static const _extraHintH = 12.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Day numbers
        SizedBox(
          height: dayNumH,
          child: Row(
            children: List.generate(7, (ci) {
              final d = weekDays[ci];
              final inMonth = d.month == month.month;
              final isSelected = _sameCalendarDay(d, selected);
              final isToday = _sameCalendarDay(d, today);
              final weekend = d.weekday == DateTime.saturday ||
                  d.weekday == DateTime.sunday;
              Color numColor = inMonth
                  ? AppColors.onSurface
                  : AppColors.onSurfaceVariant.withValues(alpha: 0.45);
              if (inMonth && weekend) {
                numColor = d.weekday == DateTime.sunday
                    ? cs.error
                    : cs.primary;
              }

              return Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: isToday
                        ? Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${d.day}',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: cs.onPrimary,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          )
                        : Text(
                            '${d.day}',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: numColor,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Events band
        if (contentH > 0)
          SizedBox(
            height: contentH,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final clip in visibleClips)
                  Positioned(
                    left: cellW * clip.startCol + 2,
                    top: clip.lane * (eventRowH + barGap),
                    width: cellW *
                            (clip.endCol - clip.startCol + 1) -
                        4,
                    height: eventRowH,
                    child: Builder(
                      builder: (context) {
                        final barBg = _parseEventHex(
                              clip.event.displayColorHex,
                            ) ??
                            cs.primary;
                        return Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          decoration: BoxDecoration(
                            color: barBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            clip.event.title,
                            maxLines: eventTitleMaxLines,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _contrastOnBackground(barBg),
                              fontWeight: FontWeight.w600,
                              fontSize: eventTitleFontSize,
                              height: 1.12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                for (var ci = 0; ci < 7; ci++)
                  for (final entry in singleAtRow[ci].entries)
                    Positioned(
                      left: cellW * ci + 2,
                      top: entry.key * (eventRowH + barGap),
                      width: cellW - 4,
                      height: eventRowH,
                      child: _SingleDayChip(
                        event: entry.value,
                        height: eventRowH,
                        maxLines: eventTitleMaxLines,
                        fontSize: eventTitleFontSize,
                      ),
                    ),
                if (anyExtra)
                  for (var ci = 0; ci < 7; ci++)
                    if (singleByDay[ci].length > maxSingleChips)
                      Positioned(
                        left: cellW * ci + 2,
                        top: eventBandH +
                            (eventRows > 0 ? barGap : 0),
                        width: cellW - 4,
                        height: _extraHintH,
                        child: Text(
                          '+${singleByDay[ci].length - maxSingleChips}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Purely visual; taps are handled by the parent day cell [GestureDetector].
class _SingleDayChip extends StatelessWidget {
  final Event event;
  final double height;
  final int maxLines;
  final double fontSize;

  const _SingleDayChip({
    required this.event,
    required this.height,
    required this.maxLines,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        _parseEventHex(event.displayColorHex) ?? Theme.of(context).colorScheme.primary;
    return Container(
      height: height,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        event.title,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _contrastOnBackground(bg),
              fontWeight: FontWeight.w600,
              fontSize: fontSize,
              height: 1.12,
            ),
      ),
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
        _parseEventHex(event.displayColorHex) ??
            Theme.of(context).colorScheme.primary;

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

}


import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import '../../../shared/utils/date_utils.dart';
import 'event_form_dialog.dart';

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final eventsProvider =
    FutureProvider.family<List<Event>, DateTimeRange>((ref, range) {
  return ref.watch(eventRepositoryProvider).getEvents(
        startDate: range.start,
        endDate: range.end,
      );
});

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime.now();

  DateTimeRange get _visibleRange {
    final start = AppDateUtils.startOfMonth(_currentMonth);
    final end = AppDateUtils.endOfMonth(_currentMonth);
    final gridStart = start.subtract(Duration(days: start.weekday - 1));
    final gridEnd = end.add(Duration(days: 7 - end.weekday));
    return DateTimeRange(start: gridStart, end: gridEnd);
  }

  void _previousMonth() => setState(
      () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));

  void _nextMonth() => setState(
      () => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

  void _goToToday() => setState(() {
        _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
        _selectedDay = DateTime.now();
      });

  Future<void> _showEventForm({Event? event}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EventFormDialog(
        event: event,
        initialDate: _selectedDay,
      ),
    );
    if (result == true) ref.invalidate(eventsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final eventsAsync = ref.watch(eventsProvider(_visibleRange));
    final allEvents = eventsAsync.valueOrNull ?? [];
    final selectedDayEvents = allEvents
        .where((e) =>
            AppDateUtils.isSameDay(e.startTime, _selectedDay) ||
            (e.allDay &&
                !_selectedDay.isBefore(AppDateUtils.startOfDay(e.startTime)) &&
                !_selectedDay.isAfter(AppDateUtils.startOfDay(e.endTime))))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final todayEventCount = allEvents
        .where((e) =>
            AppDateUtils.isSameDay(e.startTime, _selectedDay))
        .length;

    return Scaffold(
      backgroundColor: cs.surface,
      body: CustomScrollView(
        slivers: [
          // -- Flat Top Bar --
          SliverAppBar(
            pinned: true,
            backgroundColor: cs.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/members'),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.person, color: cs.onPrimary, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Familienkalender',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.mic, color: cs.primary),
                onPressed: () {},
              ),
            ],
          ),

          // -- Month Title + Nav Arrows --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppDateUtils.formatMonthYear(_currentMonth),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$todayEventCount Termine heute',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _previousMonth,
                    icon: Icon(Icons.chevron_left, color: cs.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surfaceContainer,
                      shape: const CircleBorder(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: Icon(Icons.chevron_right, color: cs.onSurface),
                    style: IconButton.styleFrom(
                      backgroundColor: cs.surfaceContainer,
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -- Calendar Grid Card --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    _WeekdayHeader(cs: cs),
                    const SizedBox(height: 4),
                    _MonthGrid(
                      visibleRange: _visibleRange,
                      currentMonth: _currentMonth,
                      selectedDay: _selectedDay,
                      events: allEvents,
                      cs: cs,
                      onDayTap: (day) => setState(() => _selectedDay = day),
                      onDayDoubleTap: (day) {
                        setState(() => _selectedDay = day);
                        _showEventForm();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -- Selected Day Header --
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppDateUtils.isToday(_selectedDay)
                          ? 'Heute, ${AppDateUtils.formatDate(_selectedDay)}'
                          : '${AppDateUtils.formatDayName(_selectedDay)}, ${AppDateUtils.formatDate(_selectedDay)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${selectedDayEvents.length} Termine',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -- Events List --
          if (eventsAsync.isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            )
          else if (selectedDayEvents.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available,
                          size: 48, color: cs.outlineVariant),
                      const SizedBox(height: 12),
                      Text(
                        'Keine Termine',
                        style: TextStyle(
                            color: cs.outline, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList.builder(
                itemCount: selectedDayEvents.length,
                itemBuilder: (context, i) {
                  final event = selectedDayEvents[i];
                  return _StitchEventCard(
                    event: event,
                    cs: cs,
                    onTap: () => _showEventForm(event: event),
                  );
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addEvent',
        onPressed: () => _showEventForm(),
        backgroundColor: cs.primaryContainer,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Weekday header row
// ---------------------------------------------------------------------------
class _WeekdayHeader extends StatelessWidget {
  final ColorScheme cs;
  const _WeekdayHeader({required this.cs});

  @override
  Widget build(BuildContext context) {
    const days = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
    return Row(
      children: days.asMap().entries.map((e) {
        final isSunday = e.key == 6;
        return Expanded(
          child: Center(
            child: Text(
              e.value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSunday ? cs.tertiary : cs.onSurfaceVariant,
                letterSpacing: 0.5,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// Month grid
// ---------------------------------------------------------------------------
class _MonthGrid extends StatelessWidget {
  final DateTimeRange visibleRange;
  final DateTime currentMonth;
  final DateTime selectedDay;
  final List<Event> events;
  final ColorScheme cs;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<DateTime> onDayDoubleTap;

  const _MonthGrid({
    required this.visibleRange,
    required this.currentMonth,
    required this.selectedDay,
    required this.events,
    required this.cs,
    required this.onDayTap,
    required this.onDayDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final gridStart = visibleRange.start;
    final weeks = <List<DateTime>>[];
    var current = gridStart;
    while (current.isBefore(visibleRange.end)) {
      weeks.add(List.generate(7, (i) => current.add(Duration(days: i))));
      current = current.add(const Duration(days: 7));
    }

    return Column(
      children: weeks.map((week) {
        return Row(
          children: week.map((day) {
            final isCurrentMonth = day.month == currentMonth.month;
            final isSelected = AppDateUtils.isSameDay(day, selectedDay);
            final isToday = AppDateUtils.isToday(day);
            final isSunday = day.weekday == DateTime.sunday;
            final dayEvents = events
                .where((e) =>
                    AppDateUtils.isSameDay(e.startTime, day) ||
                    (e.allDay &&
                        !day.isBefore(AppDateUtils.startOfDay(e.startTime)) &&
                        !day.isAfter(AppDateUtils.startOfDay(e.endTime))))
                .toList();

            return Expanded(
              child: GestureDetector(
                onTap: () => onDayTap(day),
                onDoubleTap: () => onDayDoubleTap(day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 56,
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.primary
                        : isToday
                            ? cs.surfaceContainerLowest
                            : cs.surfaceContainerLowest.withOpacity(
                                isCurrentMonth ? 1.0 : 0.0),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              (isToday || isSelected) ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? cs.onPrimary
                              : !isCurrentMonth
                                  ? cs.onSurfaceVariant.withOpacity(0.3)
                                  : isSunday
                                      ? cs.tertiary
                                      : cs.onSurface,
                        ),
                      ),
                      if (dayEvents.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: dayEvents.take(3).map((e) {
                              return Container(
                                width: 5,
                                height: 5,
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? cs.onPrimary
                                      : _parseColor(e.categoryColor) ?? cs.primary,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Stitch-style Event Card with left color bar
// ---------------------------------------------------------------------------
class _StitchEventCard extends StatelessWidget {
  final Event event;
  final ColorScheme cs;
  final VoidCallback onTap;

  const _StitchEventCard({
    required this.event,
    required this.cs,
    required this.onTap,
  });

  Color _barColor() {
    if (event.categoryColor != null) {
      try {
        return Color(
            int.parse('FF${event.categoryColor!.replaceFirst('#', '')}', radix: 16));
      } catch (_) {}
    }
    return cs.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _barColor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Left color bar
                Container(
                  width: 4,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (event.description != null &&
                              event.description!.isNotEmpty) ...[
                            Icon(Icons.location_on,
                                size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                event.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13, color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.schedule,
                              size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            event.allDay
                                ? 'Ganztaegig'
                                : '${AppDateUtils.formatTime(event.startTime)} - ${AppDateUtils.formatTime(event.endTime)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Member avatar
                if (event.members.isNotEmpty)
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(
                      event.members.first.emoji ?? event.members.first.name[0],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

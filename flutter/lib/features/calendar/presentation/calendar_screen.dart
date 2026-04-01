import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/event_repository.dart';
import '../domain/event.dart';
import '../../../shared/utils/date_utils.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_skeleton.dart';
import 'event_form_dialog.dart';
import 'day_detail_panel.dart';

enum CalendarView { month, week, threeDay, day }

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final calendarViewProvider = StateProvider<CalendarView>((ref) => CalendarView.month);

final eventsProvider = FutureProvider.family<List<Event>, DateTimeRange>((ref, range) {
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
  DateTime? _selectedDay;

  DateTimeRange get _visibleRange {
    final start = AppDateUtils.startOfMonth(_currentMonth);
    final end = AppDateUtils.endOfMonth(_currentMonth);
    final gridStart = start.subtract(Duration(days: start.weekday - 1));
    final gridEnd = end.add(Duration(days: 7 - end.weekday));
    return DateTimeRange(start: gridStart, end: gridEnd);
  }

  void _previousMonth() =>
      setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1));

  void _nextMonth() =>
      setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1));

  void _goToToday() => setState(() {
        _currentMonth = DateTime(DateTime.now().year, DateTime.now().month);
        _selectedDay = DateTime.now();
      });

  Future<void> _showEventForm({Event? event}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EventFormDialog(
        event: event,
        initialDate: _selectedDay ?? DateTime.now(),
      ),
    );
    if (result == true) ref.invalidate(eventsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(eventsProvider(_visibleRange));

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: _goToToday,
          child: Text(AppDateUtils.formatMonthYear(_currentMonth)),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.today), onPressed: _goToToday, tooltip: 'Heute'),
          IconButton(icon: const Icon(Icons.person_outline), onPressed: () => context.go('/members')),
          IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => context.go('/settings')),
        ],
      ),
      body: Column(
        children: [
          _buildNavRow(theme),
          _buildWeekdayHeader(theme),
          Expanded(
            child: eventsAsync.when(
              data: (events) => _buildMonthGrid(events, theme),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Fehler beim Laden',
                subtitle: e.toString(),
              ),
            ),
          ),
          if (_selectedDay != null)
            Expanded(
              child: DayDetailPanel(
                date: _selectedDay!,
                events: eventsAsync.valueOrNull
                        ?.where((e) =>
                            AppDateUtils.isSameDay(e.startTime, _selectedDay!) ||
                            (e.allDay &&
                                !_selectedDay!.isBefore(AppDateUtils.startOfDay(e.startTime)) &&
                                !_selectedDay!.isAfter(AppDateUtils.startOfDay(e.endTime))))
                        .toList() ??
                    [],
                onEdit: (e) => _showEventForm(event: e),
                onAdd: () => _showEventForm(),
              ),
            ),
        ],
      ),
      floatingActionButton: _selectedDay == null
          ? FloatingActionButton(
              heroTag: 'addEvent',
              onPressed: () => _showEventForm(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildNavRow(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: _previousMonth),
          Text(AppDateUtils.formatMonthYear(_currentMonth),
              style: theme.textTheme.titleMedium),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: _nextMonth),
        ],
      ),
    );
  }

  Widget _buildWeekdayHeader(ThemeData theme) {
    const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildMonthGrid(List<Event> events, ThemeData theme) {
    final gridStart = _visibleRange.start;
    final weeks = <List<DateTime>>[];
    var current = gridStart;
    while (current.isBefore(_visibleRange.end)) {
      weeks.add(List.generate(7, (i) => current.add(Duration(days: i))));
      current = current.add(const Duration(days: 7));
    }

    return ListView.builder(
      itemCount: weeks.length,
      itemBuilder: (context, weekIdx) {
        return Row(
          children: weeks[weekIdx].map((day) {
            final isCurrentMonth = day.month == _currentMonth.month;
            final isSelected = _selectedDay != null && AppDateUtils.isSameDay(day, _selectedDay!);
            final isToday = AppDateUtils.isToday(day);
            final dayEvents = events.where((e) =>
                AppDateUtils.isSameDay(e.startTime, day) ||
                (e.allDay &&
                    !day.isBefore(AppDateUtils.startOfDay(e.startTime)) &&
                    !day.isAfter(AppDateUtils.startOfDay(e.endTime)))).toList();

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() =>
                    _selectedDay = isSelected ? null : day),
                onDoubleTap: () {
                  _selectedDay = day;
                  _showEventForm();
                },
                child: Container(
                  height: 52,
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primaryContainer
                        : isToday
                            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                            : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: isToday ? FontWeight.bold : null,
                          color: isCurrentMonth
                              ? null
                              : theme.colorScheme.outline,
                        ),
                      ),
                      if (dayEvents.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayEvents
                              .take(3)
                              .map((e) => Container(
                                    width: 6, height: 6,
                                    margin: const EdgeInsets.only(top: 2, right: 1),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _categoryColor(e.categoryColor) ??
                                          theme.colorScheme.primary,
                                    ),
                                  ))
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color? _categoryColor(String? hex) {
    if (hex == null) return null;
    try {
      final cleaned = hex.replaceFirst('#', '');
      return Color(int.parse('FF$cleaned', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

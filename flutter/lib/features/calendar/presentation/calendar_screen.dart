import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/theme_context.dart';

// ── Mock Data Model ───────────────────────────────────────────────────

class _SampleEvent {
  final String title;
  final String time;
  final String detail;
  final IconData detailIcon;
  final Color categoryColor;
  final int dayOfMonth;

  const _SampleEvent({
    required this.title,
    required this.time,
    required this.detail,
    required this.detailIcon,
    required this.categoryColor,
    required this.dayOfMonth,
  });
}

// ── Calendar Screen ───────────────────────────────────────────────────

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _currentMonth;
  late DateTime _selectedDay;

  static final _monthYearFormat = DateFormat('MMMM yyyy', 'de_DE');
  static final _dayMonthFormat = DateFormat('d. MMMM', 'de_DE');
  static final _fullDayFormat = DateFormat('EEEE, d. MMMM', 'de_DE');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  // ── Month Navigation ──────────────────────────────────────────────

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _clampSelectedDay();
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _clampSelectedDay();
    });
  }

  void _clampSelectedDay() {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final clampedDay = _selectedDay.day.clamp(1, daysInMonth);
    _selectedDay = DateTime(_currentMonth.year, _currentMonth.month, clampedDay);
  }

  // ── Calendar Grid Calculation ─────────────────────────────────────

  /// Returns 42 days (6 weeks × 7 columns) for the calendar grid,
  /// starting from the Monday before (or on) the 1st of the month.
  List<DateTime> _getCalendarDays() {
    final firstOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    // Monday = 1 in DateTime.weekday; calculate offset to previous Monday.
    final startOffset = (firstOfMonth.weekday - 1) % 7;
    final startDate = firstOfMonth.subtract(Duration(days: startOffset));
    return List.generate(42, (i) => startDate.add(Duration(days: i)));
  }

  // ── Sample Events ─────────────────────────────────────────────────

  List<_SampleEvent> _eventsForMonth(Color accentPrimary) {
    final daysInMonth =
        DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final now = DateTime.now();
    final isCurrentMonth =
        now.year == _currentMonth.year && now.month == _currentMonth.month;

    if (isCurrentMonth) {
      final today = now.day;
      return [
        _SampleEvent(
          title: 'Familienfrühstück',
          time: '09:00',
          detail: 'Zu Hause',
          detailIcon: Icons.location_on_outlined,
          categoryColor: accentPrimary,
          dayOfMonth: today,
        ),
        _SampleEvent(
          title: 'Arzttermin Mama',
          time: '11:30',
          detail: 'Dr. Müller',
          detailIcon: Icons.person_outline,
          categoryColor: AppColors.secondary,
          dayOfMonth: today,
        ),
        _SampleEvent(
          title: 'Fußballtraining',
          time: '15:00',
          detail: 'Sportplatz Nord',
          detailIcon: Icons.location_on_outlined,
          categoryColor: AppColors.tertiary,
          dayOfMonth: today,
        ),
        _SampleEvent(
          title: 'Schulaufgabe abgeben',
          time: '08:00',
          detail: 'Max',
          detailIcon: Icons.person_outline,
          categoryColor: AppColors.error,
          dayOfMonth: (today + 2 > daysInMonth) ? daysInMonth : today + 2,
        ),
        _SampleEvent(
          title: 'Wochenendeinkauf',
          time: '10:00',
          detail: 'Knuspr Markt',
          detailIcon: Icons.location_on_outlined,
          categoryColor: accentPrimary,
          dayOfMonth: (today + 5 > daysInMonth) ? daysInMonth : today + 5,
        ),
      ];
    }

    // Generic events for non-current months.
    return [
      _SampleEvent(
        title: 'Team Meeting',
        time: '10:00',
        detail: 'Büro',
        detailIcon: Icons.location_on_outlined,
        categoryColor: accentPrimary,
        dayOfMonth: 3.clamp(1, daysInMonth),
      ),
      _SampleEvent(
        title: 'Yoga Kurs',
        time: '18:00',
        detail: 'Studio Mitte',
        detailIcon: Icons.location_on_outlined,
        categoryColor: AppColors.tertiary,
        dayOfMonth: 7.clamp(1, daysInMonth),
      ),
      _SampleEvent(
        title: 'Elternabend',
        time: '19:00',
        detail: 'Grundschule',
        detailIcon: Icons.location_on_outlined,
        categoryColor: AppColors.secondary,
        dayOfMonth: 12.clamp(1, daysInMonth),
      ),
      _SampleEvent(
        title: 'Geburtstagsfeier',
        time: '14:00',
        detail: 'Oma Erna',
        detailIcon: Icons.person_outline,
        categoryColor: AppColors.error,
        dayOfMonth: 18.clamp(1, daysInMonth),
      ),
    ];
  }

  List<_SampleEvent> _getEventsForDay(int dayOfMonth, Color accentPrimary) {
    return _eventsForMonth(accentPrimary)
        .where((e) => e.dayOfMonth == dayOfMonth)
        .toList();
  }

  int _todayEventCount(Color accentPrimary) {
    final now = DateTime.now();
    if (now.year != _currentMonth.year || now.month != _currentMonth.month) {
      return 0;
    }
    return _eventsForMonth(accentPrimary)
        .where((e) => e.dayOfMonth == now.day)
        .length;
  }

  // ── Helpers ───────────────────────────────────────────────────────

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final calendarDays = _getCalendarDays();
    final selectedDayEvents = _getEventsForDay(_selectedDay.day, cs.primary);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 2: KALENDER-HEADER
              _buildKalenderHeader(theme, cs),
              const SizedBox(height: 24),

              // Section 3: KALENDER-GRID
              _buildKalenderGrid(theme, calendarDays, cs),
              const SizedBox(height: 40),

              // Section 4: TAGES-HEADER
              _buildTagesHeader(theme, selectedDayEvents.length),
              const SizedBox(height: 16),

              // Section 5: EVENTS-LISTE
              _buildEventsList(theme, selectedDayEvents),
            ],
          ),
        ),

        // Section 6: FAB
        _buildFab(context),
      ],
    );
  }

  // ── Section 2: KALENDER-HEADER ────────────────────────────────────

  Widget _buildKalenderHeader(ThemeData theme, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: overline + month title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overline
                Text(
                  'KALENDERANSICHT',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 8),

                // Month title — displaySmall (36px), extrabold, tracking-tight
                Text(
                  _monthYearFormat.format(_currentMonth),
                  style: theme.textTheme.displaySmall?.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),

                // Subtitle
                Text(
                  '${_todayEventCount(cs.primary)} Termine heute',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Right: navigation arrows
          Row(
            children: [
              _HoverButton(
                size: 40,
                defaultColor: AppColors.surfaceContainerLow,
                hoverColor: AppColors.surfaceContainerHigh,
                icon: Icons.chevron_left,
                iconColor: cs.primary,
                onPressed: _previousMonth,
              ),
              const SizedBox(width: 8),
              _HoverButton(
                size: 40,
                defaultColor: AppColors.surfaceContainerLow,
                hoverColor: AppColors.surfaceContainerHigh,
                icon: Icons.chevron_right,
                iconColor: cs.primary,
                onPressed: _nextMonth,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section 3: KALENDER-GRID ──────────────────────────────────────

  Widget _buildKalenderGrid(
    ThemeData theme,
    List<DateTime> calendarDays,
    ColorScheme cs,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppColors.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.surface.withOpacity(0.15),
              blurRadius: 40,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildWeekdayHeader(theme),
            const SizedBox(height: 8),
            _buildDayGrid(theme, calendarDays, cs),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekdayHeader(ThemeData theme) {
    const weekdays = ['MO', 'DI', 'MI', 'DO', 'FR', 'SA', 'SO'];
    return Row(
      children: weekdays.asMap().entries.map((entry) {
        final isSunday = entry.key == 6;
        return Expanded(
          child: Center(
            child: Text(
              entry.value,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSunday
                    ? AppColors.secondary
                    : AppColors.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayGrid(
    ThemeData theme,
    List<DateTime> calendarDays,
    ColorScheme cs,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < calendarDays.length; i += 7) {
      final weekDays = calendarDays.sublist(i, i + 7);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: weekDays
                .map((day) => Expanded(child: _buildDayCell(theme, day, cs)))
                .toList(),
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _buildDayCell(ThemeData theme, DateTime day, ColorScheme cs) {
    final isCurrentMonth = day.month == _currentMonth.month;
    final isToday = _isToday(day);
    final isSelected = _isSameDay(day, _selectedDay);
    final isSunday = day.weekday == DateTime.sunday;
    final dayEvents = _getEventsForDay(day.day, cs.primary);
    final showHighlight = isToday || isSelected;

    return GestureDetector(
      onTap: () => setState(() => _selectedDay = day),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number with optional highlight circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showHighlight ? cs.primary : Colors.transparent,
              ),
              child: Center(
                child: Text(
                  '${day.day}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight:
                        showHighlight ? FontWeight.bold : FontWeight.w500,
                    color: showHighlight
                        ? cs.onPrimaryContainer
                        : isSunday
                            ? AppColors.secondary
                            : AppColors.onSurface
                                .withOpacity(isCurrentMonth ? 1.0 : 0.2),
                  ),
                ),
              ),
            ),

            // Event dots (max 3, 4×4 rounded-full, gap 2px)
            if (dayEvents.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dayEvents.take(3).map((event) {
                    return Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: event.categoryColor,
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Section 4: TAGES-HEADER ───────────────────────────────────────

  Widget _buildTagesHeader(ThemeData theme, int eventCount) {
    final isToday = _isToday(_selectedDay);
    final dayText = isToday
        ? 'Heute, ${_dayMonthFormat.format(_selectedDay)}'
        : _fullDayFormat.format(_selectedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Title — headlineSmall (24px), bold
          Expanded(
            child: Text(
              dayText,
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),

          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(AppColors.radiusFull),
            ),
            child: Text(
              '$eventCount Termine',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section 5: EVENTS-LISTE ───────────────────────────────────────

  Widget _buildEventsList(ThemeData theme, List<_SampleEvent> events) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.event_available,
                  size: 48, color: AppColors.outlineVariant),
              const SizedBox(height: 12),
              Text(
                'Keine Termine',
                style: TextStyle(
                    color: AppColors.outline, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: events.map((event) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CalendarEventCard(event: event),
          );
        }).toList(),
      ),
    );
  }

  // ── Section 6: FAB ────────────────────────────────────────────────

  Widget _buildFab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Positioned(
      bottom: 128,
      right: 24,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: context.accentLinearGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cs.primary.withOpacity(0.08),
              blurRadius: 40,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              // TODO: Navigate to event creation screen
            },
            child: Center(
              child: Icon(
                Icons.add,
                size: 30,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Private Widgets
// ═══════════════════════════════════════════════════════════════════════

/// Hover-aware circular button used for month navigation arrows.
class _HoverButton extends StatefulWidget {
  final double size;
  final Color defaultColor;
  final Color hoverColor;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onPressed;

  const _HoverButton({
    required this.size,
    required this.defaultColor,
    required this.hoverColor,
    required this.icon,
    required this.iconColor,
    required this.onPressed,
  });

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _isHovered ? widget.hoverColor : widget.defaultColor,
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: widget.iconColor, size: 20),
        ),
      ),
    );
  }
}

/// Calendar event card with time column, vertical separator line,
/// content area, and a hover-revealed more-button.
///
/// Layout: [Time column (48px) | Vertical line | Content | More-Button]
class _CalendarEventCard extends StatefulWidget {
  final _SampleEvent event;

  const _CalendarEventCard({required this.event});

  @override
  State<_CalendarEventCard> createState() => _CalendarEventCardState();
}

class _CalendarEventCardState extends State<_CalendarEventCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.surfaceContainerHighest
              : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Time column (48px wide) ─────────────────────────────
            SizedBox(
              width: 48,
              child: Text(
                event.time,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: event.categoryColor,
                ),
              ),
            ),

            // ── Vertical separator line ─────────────────────────────
            Container(
              width: 0.5,
              height: 48,
              color: AppColors.outlineVariant.withOpacity(0.3),
            ),
            const SizedBox(width: 16),

            // ── Content ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row: dot + title
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: event.categoryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Detail line: icon + text
                  Row(
                    children: [
                      Icon(
                        event.detailIcon,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── More button (visible on hover) ──────────────────────
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _isHovered ? 1.0 : 0.0,
              child: IconButton(
                icon: const Icon(Icons.more_vert,
                    color: AppColors.onSurfaceVariant),
                onPressed: () {
                  // TODO: Show event options menu
                },
                iconSize: 20,
                constraints:
                    const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

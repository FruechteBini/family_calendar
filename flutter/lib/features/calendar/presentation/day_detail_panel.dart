import 'package:flutter/material.dart';
import '../domain/event.dart';
import '../../../shared/utils/date_utils.dart';

class DayDetailPanel extends StatelessWidget {
  final DateTime date;
  final List<Event> events;
  final ValueChanged<Event> onEdit;
  final VoidCallback onAdd;

  const DayDetailPanel({
    super.key,
    required this.date,
    required this.events,
    required this.onEdit,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${AppDateUtils.formatDayName(date)}, ${AppDateUtils.formatDate(date)}',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: onAdd,
                  tooltip: 'Neuer Termin',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      'Keine Termine',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.outline),
                    ),
                  )
                : ListView.builder(
                    itemCount: events.length,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemBuilder: (context, i) {
                      final event = events[i];
                      return _EventTile(event: event, onTap: () => onEdit(event));
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _EventTile({required this.event, required this.onTap});

  Color _parseColor(String? hex) {
    if (hex == null) return Colors.blue;
    try {
      return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _parseColor(event.categoryColor);

    return ListTile(
      dense: true,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(event.title, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        event.allDay
            ? 'Ganztägig'
            : '${AppDateUtils.formatTime(event.startTime)} - ${AppDateUtils.formatTime(event.endTime)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: event.members.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: event.members
                  .take(3)
                  .map((m) => Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: CircleAvatar(
                          radius: 10,
                          child: Text(m.emoji ?? m.name[0],
                              style: const TextStyle(fontSize: 10)),
                        ),
                      ))
                  .toList(),
            )
          : null,
      onTap: onTap,
    );
  }
}

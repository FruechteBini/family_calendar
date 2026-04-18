import 'package:flutter/material.dart';

/// Large tap target for toggling todo completion (Material recommends ≥48 logical pixels).
class TodoCompletionControl extends StatelessWidget {
  final bool completed;
  final VoidCallback onToggle;
  final double iconSize;

  const TodoCompletionControl({
    super.key,
    required this.completed,
    required this.onToggle,
    this.iconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = completed
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return IconButton(
      tooltip: completed ? 'Als offen markieren' : 'Erledigt',
      icon: Icon(
        completed ? Icons.check_box : Icons.check_box_outlined,
        size: iconSize,
        color: color,
      ),
      onPressed: onToggle,
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.all(8),
        visualDensity: VisualDensity.standard,
      ),
    );
  }
}

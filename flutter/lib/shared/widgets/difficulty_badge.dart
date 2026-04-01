import 'package:flutter/material.dart';

class DifficultyBadge extends StatelessWidget {
  final String difficulty;

  const DifficultyBadge({super.key, required this.difficulty});

  static const _labels = {
    'einfach': 'Einfach',
    'mittel': 'Mittel',
    'schwer': 'Schwer',
  };

  static const _colors = {
    'einfach': Colors.green,
    'mittel': Colors.orange,
    'schwer': Colors.red,
  };

  static const _icons = {
    'einfach': Icons.sentiment_satisfied,
    'mittel': Icons.sentiment_neutral,
    'schwer': Icons.local_fire_department,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[difficulty] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[difficulty] ?? Icons.help, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _labels[difficulty] ?? difficulty,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

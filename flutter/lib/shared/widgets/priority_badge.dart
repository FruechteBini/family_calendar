import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import 'form_input_decoration.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  final bool compact;

  const PriorityBadge({
    super.key,
    required this.priority,
    this.compact = false,
  });

  static const _labels = {
    'none': 'Keine',
    'low': 'Niedrig',
    'medium': 'Mittel',
    'high': 'Hoch',
  };

  static const _icons = {
    'none': Icons.remove,
    'low': Icons.arrow_downward,
    'medium': Icons.remove,
    'high': Icons.arrow_upward,
  };

  Color get _color {
    switch (priority) {
      case 'high':
        return AppColors.priorityColors[3];
      case 'medium':
        return AppColors.priorityColors[2];
      case 'low':
        return AppColors.priorityColors[1];
      default:
        return AppColors.priorityColors[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (priority == 'none' && compact) return const SizedBox.shrink();

    if (compact) {
      return Icon(_icons[priority], size: 16, color: _color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icons[priority], size: 14, color: _color),
          const SizedBox(width: 4),
          Text(
            _labels[priority] ?? priority,
            style: TextStyle(fontSize: 12, color: _color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class PrioritySelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const PrioritySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: appFormInputDecoration(
        context,
        labelText: 'Priorität',
        prefixIcon: const Icon(Icons.flag_outlined),
      ),
      items: ['none', 'low', 'medium', 'high'].map((p) {
        return DropdownMenuItem(
          value: p,
          child: PriorityBadge(priority: p),
        );
      }).toList(),
      onChanged: (v) => onChanged(v ?? 'none'),
    );
  }
}

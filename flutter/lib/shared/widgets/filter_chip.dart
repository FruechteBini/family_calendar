import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Filter chip with active/inactive states.
///
/// Pill-shaped. Active uses secondary container color.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.onSelected,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool>? onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isSelected ? AppColors.secondaryContainer : AppColors.surfaceVariant;
    final textColor =
        isSelected ? AppColors.onSecondary : AppColors.onSurfaceVariant;

    return GestureDetector(
      onTap: onSelected != null ? () => onSelected!(!isSelected) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppColors.spacing3,
          vertical: 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: textColor,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: textColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

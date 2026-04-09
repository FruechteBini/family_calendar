import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Badge / Tag with optional warning variant.
///
/// Pill-shaped with bold label text.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.text,
    this.isWarning = false,
    this.icon,
  });

  final String text;
  final bool isWarning;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final bgColor =
        isWarning ? AppColors.secondaryContainer : AppColors.surfaceContainerHigh;
    final textColor =
        isWarning ? AppColors.onSecondary : AppColors.onSurfaceVariant;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppColors.radiusFull),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppColors.spacing4,
        vertical: 4,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: textColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

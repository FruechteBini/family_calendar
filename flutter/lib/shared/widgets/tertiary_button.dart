import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Tertiary text-only button with optional underline.
///
/// No background, just styled text. Optional 2px underline in secondary color.
class TertiaryButton extends StatelessWidget {
  const TertiaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.showUnderline = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool showUnderline;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (showUnderline)
            Container(
              height: 2,
              width: 24,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Notification dot indicator.
///
/// Glowing primaryFixed color dot, positioned top-right of parent via Stack.
class NotificationDot extends StatelessWidget {
  const NotificationDot({
    super.key,
    this.size = 8.0,
    this.show = true,
  });

  final double size;
  final bool show;

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryFixed,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.background,
          width: 2,
        ),
      ),
    );
  }
}

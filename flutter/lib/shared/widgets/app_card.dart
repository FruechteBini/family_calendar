import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Standard card with tonal surface background and hover animation.
///
/// No border, no shadow. Uses tonal layering for depth.
class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectivePadding =
        widget.padding ?? const EdgeInsets.all(AppColors.spacing4);

    return MouseRegion(
      onEnter: widget.onTap != null ? (_) => setState(() => _isHovered = true) : null,
      onExit: widget.onTap != null ? (_) => setState(() => _isHovered = false) : null,
      cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceContainerHighest
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          ),
          padding: effectivePadding,
          child: widget.child,
        ),
      ),
    );
  }
}

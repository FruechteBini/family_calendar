import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Checkbox / Todo item with priority variant.
///
/// Round checkbox circle, pill-shaped row background.
class TodoItem extends StatefulWidget {
  const TodoItem({
    super.key,
    required this.text,
    required this.isChecked,
    this.isPriority = false,
    this.onChanged,
    this.onTap,
  });

  final String text;
  final bool isChecked;
  final bool isPriority;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  @override
  State<TodoItem> createState() => _TodoItemState();
}

class _TodoItemState extends State<TodoItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surfaceContainerHigh
                : AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AppColors.radiusFull),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing4,
            vertical: AppColors.spacing3,
          ),
          child: Row(
            children: [
              // Checkbox circle — min. 48×48 Bedienfläche für Touch
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onChanged != null
                    ? () => widget.onChanged!(!widget.isChecked)
                    : null,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: _buildCheckbox(),
                  ),
                ),
              ),
              const SizedBox(width: AppColors.spacing3),
              // Text
              Expanded(
                child: Text(
                  widget.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.isChecked
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
                        fontWeight: FontWeight.w500,
                        decoration: widget.isChecked
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const double _glyph = 28;

  Widget _buildCheckbox() {
    if (widget.isPriority && !widget.isChecked) {
      // Priority variant: secondary border + priority_high icon
      return Container(
        width: _glyph,
        height: _glyph,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.secondary,
            width: 2,
          ),
        ),
        child: const Icon(
          Icons.priority_high,
          size: 17,
          color: AppColors.secondary,
        ),
      );
    }

    if (widget.isChecked) {
      final primary = Theme.of(context).colorScheme.primary;
      // Checked: primary border + check icon
      return Container(
        width: _glyph,
        height: _glyph,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primary,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.check,
          size: 20,
          color: primary,
        ),
      );
    }

    // Unchecked: outlineVariant border, no fill
    return Container(
      width: _glyph,
      height: _glyph,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.outlineVariant,
          width: 2,
        ),
      ),
    );
  }
}

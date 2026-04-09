import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Input field with configurable shape (pill or rounded).
///
/// No border in normal state; ghost border on focus.
class AppInputField extends StatefulWidget {
  const AppInputField({
    super.key,
    this.hintText,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.pillShape = true,
    this.onChanged,
    this.onSubmitted,
  });

  final String? hintText;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool pillShape;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onSubmitted;

  @override
  State<AppInputField> createState() => _AppInputFieldState();
}

class _AppInputFieldState extends State<AppInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.pillShape
        ? BorderRadius.circular(AppColors.radiusFull)
        : BorderRadius.circular(AppColors.radiusDefault);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: borderRadius,
        border: _isFocused
            ? Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                width: 2,
              )
            : null,
      ),
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurface,
            ),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: AppColors.onSurfaceVariant,
                  size: 20,
                )
              : null,
          suffixIcon: widget.suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing4,
            vertical: AppColors.spacing3,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

Widget? _hiddenInputCounter(
  BuildContext context, {
  required int currentLength,
  required bool isFocused,
  int? maxLength,
}) =>
    null;

InputDecoration _labeledFieldDecoration(
  BuildContext context, {
  String? hintText,
  Widget? prefixIcon,
}) {
  final theme = Theme.of(context);
  final variant = theme.colorScheme.onSurfaceVariant;
  return InputDecoration(
    hintText: hintText,
    hintStyle: theme.textTheme.bodyLarge?.copyWith(
      color: variant.withValues(alpha: 0.75),
    ),
    prefixIcon: prefixIcon,
    filled: true,
    contentPadding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );
}

/// Single-line field with label above; matches [LabeledMultilineTextField] for dialogs.
class LabeledOutlineTextField extends StatelessWidget {
  const LabeledOutlineTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.showCounter = false,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final Widget? prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  /// When [maxLength] is set, hide the character counter under the field.
  final bool showCounter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          style: theme.textTheme.bodyLarge,
          buildCounter:
              maxLength != null && !showCounter ? _hiddenInputCounter : null,
          decoration: _labeledFieldDecoration(
            context,
            hintText: hintText,
            prefixIcon: prefixIcon,
          ),
        ),
      ],
    );
  }
}

/// Multiline text field with the label above the box (readable size), not as a
/// floating label inside the field.
class LabeledMultilineTextField extends StatelessWidget {
  const LabeledMultilineTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.minLines = 4,
    this.maxLines = 8,
    this.validator,
    this.textCapitalization = TextCapitalization.sentences,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final int minLines;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          textCapitalization: textCapitalization,
          style: theme.textTheme.bodyLarge,
          validator: validator,
          decoration: _labeledFieldDecoration(context, hintText: hintText),
        ),
      ],
    );
  }
}

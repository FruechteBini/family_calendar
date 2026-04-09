import 'package:flutter/material.dart';

/// Merges [labelText] / icons with [ThemeData.inputDecorationTheme] so dropdowns
/// and [InputDecorator]s match [TextFormField] (e.g. Titel) in dialogs.
InputDecoration appFormInputDecoration(
  BuildContext context, {
  required String labelText,
  Widget? prefixIcon,
  Widget? suffixIcon,
  String? hintText,
}) {
  return InputDecoration(
    labelText: labelText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    hintText: hintText,
  ).applyDefaults(Theme.of(context).inputDecorationTheme);
}

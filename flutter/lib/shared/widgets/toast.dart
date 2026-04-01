import 'package:flutter/material.dart';

enum ToastType { success, error, info, warning }

void showAppToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final colors = {
    ToastType.success: Colors.green,
    ToastType.error: Colors.red,
    ToastType.info: Theme.of(context).colorScheme.primary,
    ToastType.warning: Colors.orange,
  };
  final icons = {
    ToastType.success: Icons.check_circle_outline,
    ToastType.error: Icons.error_outline,
    ToastType.info: Icons.info_outline,
    ToastType.warning: Icons.warning_amber,
  };

  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(icons[type], color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: colors[type],
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: Colors.white,
        onPressed: () =>
            ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    ),
  );
}

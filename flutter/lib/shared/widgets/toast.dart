import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

enum ToastType { success, error, info, warning }

/// Root [MaterialApp] should set [scaffoldMessengerKey] to this key so share / background flows can show toasts.
final appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void showAppToastGlobal({
  required String message,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 2),
}) {
  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;
  final colors = {
    ToastType.success: Colors.green,
    ToastType.error: Colors.red,
    ToastType.info: AppColors.primary,
    ToastType.warning: Colors.orange,
  };
  final icons = {
    ToastType.success: Icons.check_circle_outline,
    ToastType.error: Icons.error_outline,
    ToastType.info: Icons.info_outline,
    ToastType.warning: Icons.warning_amber,
  };
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 104),
      content: Row(
        children: [
          Icon(icons[type], color: AppColors.onSurface, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
      backgroundColor: colors[type],
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: AppColors.onSurface,
        onPressed: messenger.hideCurrentSnackBar,
      ),
    ),
  );
}

void showAppToast(
  BuildContext context, {
  required String message,
  ToastType type = ToastType.info,
  Duration duration = const Duration(seconds: 2),
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

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.of(context).padding.bottom + 88,
      ),
      content: Row(
        children: [
          Icon(icons[type], color: AppColors.onSurface, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.onSurface)),
          ),
        ],
      ),
      backgroundColor: colors[type],
      duration: duration,
      action: SnackBarAction(
        label: 'OK',
        textColor: AppColors.onSurface,
        onPressed: messenger.hideCurrentSnackBar,
      ),
    ),
  );
}

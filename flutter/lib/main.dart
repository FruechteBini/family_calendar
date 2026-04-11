import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app/app.dart';
import 'core/notifications/push_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('de_DE');
  runApp(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          // Fire-and-forget init. If Firebase isn't configured yet, it stays disabled.
          unawaited(ref.read(pushNotificationsProvider).init());
          return const FamilienkalenderApp();
        },
      ),
    ),
  );
}

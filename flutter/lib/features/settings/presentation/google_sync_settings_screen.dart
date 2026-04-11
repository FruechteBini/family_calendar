import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/widgets/toast.dart';

/// Google incremental auth: a new serverAuthCode must cover **all** scopes the
/// account should keep. Requesting only Tasks after Calendar was enabled yields
/// tokens that can drop Calendar — and parallel toggles can race auth codes.
class GoogleSyncSettingsScreen extends ConsumerStatefulWidget {
  const GoogleSyncSettingsScreen({super.key});

  @override
  ConsumerState<GoogleSyncSettingsScreen> createState() =>
      _GoogleSyncSettingsScreenState();
}

class _GoogleSyncSettingsScreenState
    extends ConsumerState<GoogleSyncSettingsScreen> {
  /// Serialize grant + settings updates so two switches cannot overlap.
  Future<void> _mutex = Future.value();

  Future<T> _synchronized<T>(Future<T> Function() fn) async {
    final previous = _mutex;
    final completer = Completer<void>();
    _mutex = completer.future;
    try {
      await previous;
      return await fn();
    } finally {
      completer.complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final dio = ref.watch(dioProvider);

    Future<void> toggleCalendar(bool enabled) => _synchronized(() async {
          try {
            if (enabled) {
              // Nach Mutex: aktuellen User lesen (anderer Schalter kann schon fertig sein).
              final u = ref.read(authStateProvider).user;
              final alsoTasks = u?.syncTodosEnabled ?? false;
              await ref.read(authStateProvider.notifier).grantGoogleSyncScopes(
                    calendar: true,
                    tasks: alsoTasks,
                  );
            }
            await dio.put(
              Endpoints.googleSyncSettings,
              data: {'sync_calendar_enabled': enabled},
            );
            await ref.read(authStateProvider.notifier).refreshUser();
          } on ApiException catch (e) {
            if (context.mounted) {
              showAppToast(context, message: e.message, type: ToastType.error);
            }
          } on DioException catch (e) {
            if (context.mounted) {
              showAppToast(
                context,
                message: ApiException.fromDioError(e).message,
                type: ToastType.error,
              );
            }
          }
        });

    Future<void> toggleTodos(bool enabled) => _synchronized(() async {
          try {
            if (enabled) {
              final u = ref.read(authStateProvider).user;
              final alsoCalendar = u?.syncCalendarEnabled ?? false;
              await ref.read(authStateProvider.notifier).grantGoogleSyncScopes(
                    calendar: alsoCalendar,
                    tasks: true,
                  );
            }
            await dio.put(
              Endpoints.googleSyncSettings,
              data: {'sync_todos_enabled': enabled},
            );
            await ref.read(authStateProvider.notifier).refreshUser();
          } on ApiException catch (e) {
            if (context.mounted) {
              showAppToast(context, message: e.message, type: ToastType.error);
            }
          } on DioException catch (e) {
            if (context.mounted) {
              showAppToast(
                context,
                message: ApiException.fromDioError(e).message,
                type: ToastType.error,
              );
            }
          }
        });

    Future<void> triggerSync() async {
      try {
        await dio.post(Endpoints.googleSyncTrigger);
        if (context.mounted) {
          showAppToast(context,
              message: 'Sync gestartet', type: ToastType.success);
        }
      } on ApiException catch (e) {
        if (context.mounted) {
          showAppToast(context, message: e.message, type: ToastType.error);
        }
      } on DioException catch (e) {
        if (context.mounted) {
          showAppToast(
            context,
            message: ApiException.fromDioError(e).message,
            type: ToastType.error,
          );
        }
      }
    }

    final googleEmail = user?.googleEmail;
    final isLinked = googleEmail != null && googleEmail.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Google-Synchronisation')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Google-Konto'),
            subtitle: Text(isLinked ? googleEmail : 'Nicht verbunden'),
            trailing: isLinked
                ? OutlinedButton(
                    onPressed: () async {
                      try {
                        await ref.read(authStateProvider.notifier).unlinkGoogle();
                        if (context.mounted) {
                          showAppToast(context,
                              message: 'Google getrennt',
                              type: ToastType.success);
                        }
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          showAppToast(context,
                              message: e.message, type: ToastType.error);
                        }
                      }
                    },
                    child: const Text('Trennen'),
                  )
                : FilledButton(
                    onPressed: () async {
                      try {
                        await ref.read(authStateProvider.notifier).linkGoogle();
                        if (context.mounted) {
                          showAppToast(context,
                              message: 'Google verbunden',
                              type: ToastType.success);
                        }
                      } on ApiException catch (e) {
                        if (context.mounted) {
                          showAppToast(context,
                              message: e.message, type: ToastType.error);
                        }
                      }
                    },
                    child: const Text('Verbinden'),
                  ),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Kalender → Google Calendar'),
            subtitle: const Text('Bidirektionaler Sync von Terminen'),
            value: user?.syncCalendarEnabled ?? false,
            onChanged: isLinked ? toggleCalendar : null,
          ),
          SwitchListTile(
            title: const Text('Todos → Google Tasks'),
            subtitle: const Text('Bidirektionaler Sync von Aufgaben'),
            value: user?.syncTodosEnabled ?? false,
            onChanged: isLinked ? toggleTodos : null,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('Jetzt synchronisieren'),
            subtitle: const Text('Manuell einen Sync anstoßen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: isLinked ? triggerSync : null,
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Hinweis: Für den Sync werden zusätzliche Google-Berechtigungen benötigt. '
              'Du kannst Kalender- und Todo-Sync getrennt aktivieren.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}


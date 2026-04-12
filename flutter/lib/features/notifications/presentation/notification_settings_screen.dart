import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notifications/push_notifications.dart';
import '../../../shared/widgets/toast.dart';
import '../data/notification_repository.dart';
import '../domain/notification_preference.dart';

final _prefsProvider = FutureProvider<List<NotificationPreference>>((ref) async {
  return ref.watch(notificationRepositoryProvider).getPreferences();
});

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final push = ref.watch(pushNotificationsProvider);
    final prefsAsync = ref.watch(_prefsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Benachrichtigungen')),
      body: prefsAsync.when(
        data: (prefs) {
          final map = {for (final p in prefs) p.type: p.enabled};

          Future<void> set(NotificationType t, bool enabled) async {
            final updated = [
              for (final p in prefs)
                if (p.type == t)
                  NotificationPreference(type: p.type, enabled: enabled)
                else
                  p,
            ];
            try {
              await ref.read(notificationRepositoryProvider).updatePreferences(updated);
              ref.invalidate(_prefsProvider);
            } on ApiException catch (e) {
              if (context.mounted) {
                showAppToast(context, message: e.message, type: ToastType.error);
              }
            }
          }

          Widget section(String title, List<Widget> children) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text(title, style: Theme.of(context).textTheme.titleSmall),
                    ),
                    ...children,
                  ],
                ),
              );

          SwitchListTile tile(NotificationType t, String title, String subtitle) {
            return SwitchListTile(
              title: Text(title),
              subtitle: Text(subtitle),
              value: map[t] ?? true,
              onChanged: (v) => set(t, v),
            );
          }

          return ListView(
            children: [
              if (!push.isAvailable)
                const ListTile(
                  leading: Icon(Icons.notifications_off_outlined),
                  title: Text('Push ist nicht aktiv'),
                  subtitle: Text('Firebase ist auf diesem Gerät noch nicht konfiguriert oder Berechtigungen fehlen.'),
                )
              else
                const ListTile(
                  leading: Icon(Icons.notifications_active_outlined),
                  title: Text('Push ist aktiv'),
                  subtitle: Text('Du kannst unten festlegen, welche Push-Benachrichtigungen du erhalten möchtest.'),
                ),
              const Divider(),
              section('Erinnerungen', [
                tile(NotificationType.eventReminder, 'Termin-Erinnerungen', 'Erinnerungen vor dem Termin'),
                tile(NotificationType.todoReminder, 'Todo-Erinnerungen', 'Erinnerungen am Fälligkeitstag'),
                tile(NotificationType.noteReminder, 'Notiz-Erinnerungen', 'Erinnerungen aus Notizen'),
              ]),
              section('Zuweisungen', [
                tile(NotificationType.eventAssigned, 'Neuer Termin zugewiesen', 'Wenn dir ein Termin zugewiesen wird'),
                tile(NotificationType.todoAssigned, 'Neues Todo zugewiesen', 'Wenn dir ein Todo zugewiesen wird'),
                tile(NotificationType.proposalNew, 'Neuer Terminvorschlag', 'Wenn es einen neuen Vorschlag gibt'),
              ]),
              section('Updates', [
                tile(NotificationType.eventUpdated, 'Termin geändert', 'Wenn ein zugewiesener Termin aktualisiert wird'),
                tile(NotificationType.eventDeleted, 'Termin gelöscht', 'Wenn ein zugewiesener Termin gelöscht wird'),
                tile(NotificationType.proposalResponse, 'Antwort auf Vorschlag', 'Wenn jemand auf deinen Vorschlag antwortet'),
                tile(NotificationType.todoCompleted, 'Todo erledigt', 'Wenn ein Todo erledigt wurde'),
              ]),
              section('Sonstiges', [
                tile(NotificationType.shoppingListChanged, 'Einkaufsliste geändert', 'Wenn die Einkaufsliste aktualisiert wird'),
                tile(NotificationType.mealPlanChanged, 'Essensplan geändert', 'Wenn der Essensplan aktualisiert wird'),
                tile(NotificationType.noteComment, 'Notiz-Kommentar', 'Wenn jemand auf eine Notiz kommentiert'),
              ]),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }
}


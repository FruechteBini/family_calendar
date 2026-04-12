import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';

/// Todos → Dringlichkeits-Stufen, Kategorien
class SettingsTodosMenuScreen extends StatelessWidget {
  const SettingsTodosMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Dringlichkeits-Stufen'),
            subtitle: const Text('Zeiten pro Stufe bearbeiten, löschen, neu anlegen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notification-levels'),
          ),
          ListTile(
            leading: const Icon(Icons.label_outlined),
            title: const Text('Kategorien'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/categories'),
          ),
        ],
      ),
    );
  }
}

/// Notizen → Notiz-Kategorien, Notiz-Tags
class SettingsNotesMenuScreen extends StatelessWidget {
  const SettingsNotesMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notizen')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: const Text('Notiz-Kategorien'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/note-categories'),
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('Notiz-Tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/note-tags'),
          ),
        ],
      ),
    );
  }
}

/// Familie → Familienmitglieder, Einladungscode
class SettingsFamilyMenuScreen extends ConsumerWidget {
  const SettingsFamilyMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Familie')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Familienmitglieder'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/members'),
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Einladungscode anzeigen'),
            subtitle: const Text('Code anzeigen und teilen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFamilyInfo(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _showFamilyInfo(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/auth/family');
      final data = response.data as Map<String, dynamic>;
      if (!context.mounted) return;
      final inviteCode = (data['invite_code'] as String?)?.trim();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(data['name'] as String? ?? 'Familie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Einladungscode:'),
              const SizedBox(height: 8),
              SelectableText(
                (inviteCode != null && inviteCode.isNotEmpty) ? inviteCode : '-',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              const Text('Teile diesen Code mit Familienmitgliedern.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: (inviteCode == null || inviteCode.isEmpty)
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: inviteCode));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        showAppToast(
                          ctx,
                          message: 'Familiencode kopiert',
                          type: ToastType.success,
                        );
                      }
                    },
              child: const Text('Teilen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } catch (e) {
      if (context.mounted) showAppToast(context, message: 'Fehler: $e', type: ToastType.error);
    }
  }
}

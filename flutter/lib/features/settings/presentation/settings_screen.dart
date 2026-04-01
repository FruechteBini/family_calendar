import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../app/app.dart';
import '../../../shared/widgets/toast.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final serverUrl = ref.watch(serverUrlProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: ListView(
        children: [
          // User info
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        child: Text(authState.user?.username[0].toUpperCase() ?? '?'),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(authState.user?.username ?? '', style: theme.textTheme.titleMedium),
                          Text('Familie-ID: ${authState.user?.familyId ?? '-'}', style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(),

          // Theme
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Design'),
            subtitle: Text(themeMode == ThemeMode.system ? 'System' : themeMode == ThemeMode.dark ? 'Dunkel' : 'Hell'),
            onTap: () {
              final next = switch (themeMode) {
                ThemeMode.system => ThemeMode.light,
                ThemeMode.light => ThemeMode.dark,
                ThemeMode.dark => ThemeMode.system,
              };
              ref.read(themeModeProvider.notifier).state = next;
            },
          ),

          // Server URL
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Server-URL'),
            subtitle: Text(serverUrl),
            onTap: () => _editServerUrl(context, ref, serverUrl),
          ),

          // Navigation shortcuts
          const Divider(),
          ListTile(
            leading: const Icon(Icons.people_outlined),
            title: const Text('Familienmitglieder'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/members'),
          ),
          ListTile(
            leading: const Icon(Icons.label_outlined),
            title: const Text('Kategorien'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/categories'),
          ),

          // Family info
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Familie'),
            subtitle: const Text('Einladungscode anzeigen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFamilyInfo(context, ref),
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Abmelden', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Abmelden?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
                    FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Abmelden')),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authStateProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _editServerUrl(BuildContext context, WidgetRef ref, String currentUrl) async {
    final controller = TextEditingController(text: currentUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server-URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'http://192.168.1.100:8000'),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Speichern')),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      await ref.read(authStateProvider.notifier).setServerUrl(result);
      if (context.mounted) showAppToast(context, message: 'Server-URL aktualisiert', type: ToastType.info);
    }
  }

  Future<void> _showFamilyInfo(BuildContext context, WidgetRef ref) async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/api/auth/family');
      final data = response.data as Map<String, dynamic>;
      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(data['name'] as String? ?? 'Familie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Einladungscode:'),
              const SizedBox(height: 8),
              SelectableText(
                data['invite_code'] as String? ?? '-',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 8),
              const Text('Teile diesen Code mit Familienmitgliedern.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
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

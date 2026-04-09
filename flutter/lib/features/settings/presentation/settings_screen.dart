import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import '../../../app/app.dart';
import '../../../core/api/api_client.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/toast.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final themeMode = ref.watch(themeModeProvider);
    final accentAsync = ref.watch(accentSeedColorProvider);
    final accentColor = accentAsync.valueOrNull ?? AppColors.primary;
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
          ListTile(
            leading: CircleAvatar(
              backgroundColor: accentColor,
              radius: 16,
              child: const Icon(Icons.color_lens_outlined, size: 18, color: Colors.black54),
            ),
            title: const Text('Sekundärfarbe'),
            subtitle: const Text('Akzent für Navigation, Buttons und Listen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAccentColorPicker(context, ref, accentColor),
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
          ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: const Text('Notiz-Kategorien'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/note-categories'),
          ),
          ListTile(
            leading: const Icon(Icons.sell_outlined),
            title: const Text('Notiz-Tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/note-tags'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/app-info'),
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

  void _showAccentColorPicker(
    BuildContext context,
    WidgetRef ref,
    Color initial,
  ) {
    var selected = initial;
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sekundärfarbe wählen'),
              content: SingleChildScrollView(
                child: ColorPicker(
                  pickerColor: selected,
                  onColorChanged: (c) => setDialogState(() => selected = c),
                  enableAlpha: false,
                  labelTypes: const [],
                  pickerAreaHeightPercent: 0.85,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(accentSeedColorProvider.notifier)
                        .resetAccent();
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Standard'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Abbrechen'),
                ),
                FilledButton(
                  onPressed: () async {
                    await ref
                        .read(accentSeedColorProvider.notifier)
                        .setAccent(selected);
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Übernehmen'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

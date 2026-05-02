import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/ui_scale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
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

          _UiScaleTile(),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.checklist_outlined),
            title: const Text('Todos'),
            subtitle: const Text('Dringlichkeits-Stufen und Kategorien'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/todos'),
          ),
          ListTile(
            leading: const Icon(Icons.note_alt_outlined),
            title: const Text('Notizen'),
            subtitle: const Text('Notiz-Kategorien und Notiz-Tags'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/notes'),
          ),
          ListTile(
            leading: const Icon(Icons.family_restroom),
            title: const Text('Familie'),
            subtitle: const Text('Familienmitglieder und Einladungscode'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/family'),
          ),
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Kalenderfarben'),
            subtitle: const Text('Vorgabe für persönliche und Familien-Termine'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/calendar-colors'),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Info'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/app-info'),
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Benachrichtigungen'),
            subtitle: const Text('Push (Termine, Todos, Vorschläge, …)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notification-settings'),
          ),
          ListTile(
            leading: const Icon(Icons.sync_outlined),
            title: const Text('Google-Synchronisation'),
            subtitle: const Text('Google Login, Calendar & Tasks Sync'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/google-sync'),
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

class _UiScaleTile extends ConsumerWidget {
  static const _steps = [0.75, 0.80, 0.85, 0.90, 0.95, 1.00];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scaleAsync = ref.watch(uiScaleProvider);
    final current = scaleAsync.valueOrNull ?? defaultUiScale;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.zoom_out_map, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Darstellungsgröße', style: theme.textTheme.bodyLarge),
                    Text(
                      'Kleinere Werte zeigen mehr Inhalt',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(current * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('75%', style: theme.textTheme.labelSmall),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    allowedInteraction: SliderInteraction.tapAndSlide,
                  ),
                  child: Slider(
                    value: current,
                    min: minUiScale,
                    max: maxUiScale,
                    divisions: _steps.length - 1,
                    label: '${(current * 100).round()}%',
                    onChanged: (v) {
                      final snapped = _snapToStep(v);
                      ref.read(uiScaleProvider.notifier).setScale(snapped);
                    },
                  ),
                ),
              ),
              Text('100%', style: theme.textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }

  static double _snapToStep(double value) {
    double closest = _steps.first;
    double minDiff = (value - closest).abs();
    for (final s in _steps) {
      final diff = (value - s).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = s;
      }
    }
    return closest;
  }
}

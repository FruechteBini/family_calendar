import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/toast.dart';
import '../data/notification_repository.dart';
import '../domain/notification_level.dart';
import 'notification_level_editor.dart';

final _levelsProvider = FutureProvider<List<NotificationLevel>>((ref) async {
  return ref.watch(notificationRepositoryProvider).listLevels();
});

class NotificationLevelsScreen extends ConsumerWidget {
  const NotificationLevelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final levelsAsync = ref.watch(_levelsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Dringlichkeits-Stufen')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showDialog<bool>(
            context: context,
            builder: (_) => const NotificationLevelEditor(),
          );
          if (created == true) ref.invalidate(_levelsProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Neue Stufe'),
      ),
      body: levelsAsync.when(
        data: (levels) {
          final items = [...levels]..sort((a, b) => a.position.compareTo(b.position));
          return ReorderableListView.builder(
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex -= 1;
              final updated = [...items];
              final moved = updated.removeAt(oldIndex);
              updated.insert(newIndex, moved);
              try {
                await ref.read(notificationRepositoryProvider).reorderLevels(updated);
                ref.invalidate(_levelsProvider);
              } on ApiException catch (e) {
                if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
              }
            },
            itemBuilder: (context, i) {
              final lvl = items[i];
              final chips = lvl.remindersMinutes.map(_formatMinutes).where((s) => s.isNotEmpty).toList();
              return ListTile(
                key: ValueKey(lvl.id),
                leading: const Icon(Icons.drag_handle),
                title: Row(
                  children: [
                    Expanded(child: Text(lvl.name)),
                    if (lvl.isDefault)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Chip(
                          label: const Text('Standard'),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                subtitle: chips.isEmpty
                    ? const Text('Keine Push-Erinnerungen')
                    : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final c in chips)
                            Chip(
                              label: Text(c),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final changed = await showDialog<bool>(
                    context: context,
                    builder: (_) => NotificationLevelEditor(level: lvl),
                  );
                  if (changed == true) ref.invalidate(_levelsProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }

  static String _formatMinutes(int m) {
    if (m == 0) return 'Zum Termin';
    if (m % (60 * 24 * 7) == 0) return '${m ~/ (60 * 24 * 7)} Woche(n) vorher';
    if (m % (60 * 24) == 0) return '${m ~/ (60 * 24)} Tag(e) vorher';
    if (m % 60 == 0) return '${m ~/ 60} Stunde(n) vorher';
    return '$m min vorher';
  }
}


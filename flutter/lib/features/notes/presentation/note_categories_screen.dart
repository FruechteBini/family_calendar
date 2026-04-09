import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_category_repository.dart';
import '../domain/note_category.dart';

final noteCategoriesListProvider = FutureProvider<List<NoteCategory>>((ref) {
  return ref.watch(noteCategoryRepositoryProvider).getCategories();
});

class NoteCategoriesScreen extends ConsumerStatefulWidget {
  const NoteCategoriesScreen({super.key});

  @override
  ConsumerState<NoteCategoriesScreen> createState() =>
      _NoteCategoriesScreenState();
}

class _NoteCategoriesScreenState extends ConsumerState<NoteCategoriesScreen> {
  List<NoteCategory>? _local;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(noteCategoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notiz-Kategorien')),
      body: async.when(
        data: (cats) {
          _local ??= [...cats];
          final list = _local!;
          if (cats.isNotEmpty && list.length != cats.length) {
            _local = [...cats];
          }
          return list.isEmpty
              ? const EmptyState(
                  icon: Icons.folder_outlined,
                  title: 'Keine Notiz-Kategorien',
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _local = null;
                    ref.invalidate(noteCategoriesListProvider);
                  },
                  child: ReorderableListView.builder(
                    itemCount: list.length,
                    onReorder: (oldIndex, newIndex) async {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = list.removeAt(oldIndex);
                        list.insert(newIndex, item);
                      });
                      try {
                        await ref
                            .read(noteCategoryRepositoryProvider)
                            .reorderCategories(list.map((c) => c.id).toList());
                        ref.invalidate(noteCategoriesListProvider);
                      } on ApiException catch (e) {
                        if (mounted) {
                          showAppToast(context,
                              message: e.message, type: ToastType.error);
                        }
                      }
                    },
                    itemBuilder: (_, i) {
                      final c = list[i];
                      return ListTile(
                        key: ValueKey('ncat_${c.id}'),
                        leading: Text(c.icon, style: const TextStyle(fontSize: 22)),
                        title: Text(c.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () async {
                                await _form(c);
                                _local = null;
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await _delete(c);
                                _local = null;
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Fehler',
          subtitle: e.toString(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'noteCatAdd',
        onPressed: () async {
          await _form();
          _local = null;
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _form([NoteCategory? cat]) async {
    final name = TextEditingController(text: cat?.name ?? '');
    final color = TextEditingController(text: cat?.color ?? '#1565C0');
    final icon = TextEditingController(text: cat?.icon ?? '📝');
    final edit = cat != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(edit ? 'Kategorie bearbeiten' : 'Neue Notiz-Kategorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: color,
              decoration: const InputDecoration(
                labelText: 'Farbe (#RRGGBB)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: icon,
              decoration: const InputDecoration(
                labelText: 'Icon (Emoji)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(edit ? 'Speichern' : 'Erstellen'),
          ),
        ],
      ),
    );
    if (ok != true || name.text.trim().isEmpty) return;
    final repo = ref.read(noteCategoryRepositoryProvider);
    final data = {
      'name': name.text.trim(),
      'color': color.text.trim(),
      'icon': icon.text.trim().isEmpty ? '📝' : icon.text.trim(),
    };
    try {
      if (edit) {
        await repo.updateCategory(cat.id, data);
      } else {
        await repo.createCategory(data);
      }
      ref.invalidate(noteCategoriesListProvider);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _delete(NoteCategory c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Löschen?'),
        content: Text('"${c.name}" löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(noteCategoryRepositoryProvider).deleteCategory(c.id);
      ref.invalidate(noteCategoriesListProvider);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }
}

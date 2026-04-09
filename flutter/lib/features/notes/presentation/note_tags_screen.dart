import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../data/note_tag_repository.dart';
import '../domain/note_tag.dart';

final noteTagsListProvider = FutureProvider<List<NoteTag>>((ref) {
  return ref.watch(noteTagRepositoryProvider).getTags();
});

class NoteTagsScreen extends ConsumerStatefulWidget {
  const NoteTagsScreen({super.key});

  @override
  ConsumerState<NoteTagsScreen> createState() => _NoteTagsScreenState();
}

class _NoteTagsScreenState extends ConsumerState<NoteTagsScreen> {
  Future<void> _edit(NoteTag? tag) async {
    final name = TextEditingController(text: tag?.name ?? '');
    final color = TextEditingController(text: tag?.color ?? '#6B7280');
    final edit = tag != null;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(edit ? 'Tag bearbeiten' : 'Neuer Tag'),
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
    final repo = ref.read(noteTagRepositoryProvider);
    final data = {
      'name': name.text.trim(),
      'color': color.text.trim(),
    };
    try {
      if (edit && tag != null) {
        await repo.updateTag(tag.id, data);
      } else {
        await repo.createTag(data);
      }
      ref.invalidate(noteTagsListProvider);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _delete(NoteTag t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tag löschen?'),
        content: Text('"${t.name}"'),
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
      await ref.read(noteTagRepositoryProvider).deleteTag(t.id);
      ref.invalidate(noteTagsListProvider);
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(noteTagsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notiz-Tags')),
      body: async.when(
        data: (tags) => tags.isEmpty
            ? const EmptyState(
                icon: Icons.sell_outlined,
                title: 'Keine Tags',
              )
            : RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(noteTagsListProvider);
                },
                child: ListView.builder(
                  itemCount: tags.length,
                  itemBuilder: (_, i) {
                    final t = tags[i];
                    Color chip;
                    try {
                      chip = Color(
                          int.parse(t.color.replaceFirst('#', '0xFF')));
                    } catch (_) {
                      chip = Colors.grey;
                    }
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: chip, radius: 8),
                      title: Text(t.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edit(t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(t),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Fehler',
          subtitle: e.toString(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'noteTagAdd',
        onPressed: () => _edit(null),
        child: const Icon(Icons.add),
      ),
    );
  }
}

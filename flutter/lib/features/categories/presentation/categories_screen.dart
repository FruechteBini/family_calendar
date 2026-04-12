import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../core/api/api_client.dart';

final categoriesListProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  List<Category>? _local;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategorien')),
      body: categoriesAsync.when(
        data: (cats) {
          _local ??= [...cats];
          final list = _local!;
          if (cats.isNotEmpty && list.length != cats.length) {
            // resync when count changed (create/delete)
            _local = [...cats];
          }
          return list.isEmpty
              ? const EmptyState(
                  icon: Icons.label_outline, title: 'Keine Kategorien')
              : RefreshIndicator(
                  onRefresh: () async {
                    _local = null;
                    ref.invalidate(categoriesListProvider);
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
                            .read(categoryRepositoryProvider)
                            .reorderCategories(list.map((c) => c.id).toList());
                        ref.invalidate(categoriesListProvider);
                      } on ApiException catch (e) {
                        if (mounted) {
                          showAppToast(context,
                              message: e.message, type: ToastType.error);
                        }
                      }
                    },
                    itemBuilder: (_, i) => _CategoryTile(
                      key: ValueKey('cat_${list[i].id}'),
                      index: i,
                      category: list[i],
                      onEdit: () async {
                        await _showForm(context, ref, category: list[i]);
                        _local = null;
                      },
                      onDelete: () async {
                        await _delete(context, ref, list[i]);
                        _local = null;
                      },
                    ),
                  ),
                );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
            icon: Icons.error_outline, title: 'Fehler', subtitle: e.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCategory',
        onPressed: () async {
          await _showForm(context, ref);
          _local = null;
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref,
      {Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final colorController =
        TextEditingController(text: category?.color ?? '#1565C0');
    final isEdit = category != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Kategorie bearbeiten' : 'Neue Kategorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LabeledOutlineTextField(
              label: 'Name',
              controller: nameController,
              prefixIcon: const Icon(Icons.label_outline),
            ),
            const SizedBox(height: 12),
            LabeledOutlineTextField(
              label: 'Farbe (Hex)',
              controller: colorController,
              hintText: '#1565C0',
              prefixIcon: const Icon(Icons.palette_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Speichern' : 'Erstellen')),
        ],
      ),
    );
    if (result != true || nameController.text.trim().isEmpty) return;
    try {
      final data = {
        'name': nameController.text.trim(),
        'color': colorController.text.trim()
      };
      final repo = ref.read(categoryRepositoryProvider);
      if (isEdit) {
        await repo.updateCategory(category.id, data);
      } else {
        await repo.createCategory(data);
      }
      ref.invalidate(categoriesListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategorie löschen?'),
        content: Text('"${category.name}" löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Löschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(categoriesListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final int index;
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({
    super.key,
    required this.index,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  Color _parseColor() {
    try {
      return Color(int.parse(
          'FF${category.color.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 16),
      title: Text(category.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReorderableDragStartListener(
            index: index,
            child: Icon(Icons.drag_handle, color: Theme.of(context).hintColor),
          ),
          IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit),
          IconButton(
              icon:
                  const Icon(Icons.delete_outline, size: 20, color: Colors.red),
              onPressed: onDelete),
        ],
      ),
    );
  }
}

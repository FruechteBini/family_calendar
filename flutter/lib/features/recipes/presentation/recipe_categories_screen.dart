import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/recipe_category_repository.dart';
import '../domain/recipe_category.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../core/api/api_client.dart';
import '../../../core/sync/mutation_refresh.dart';

final recipeCategoriesListProvider =
    FutureProvider<List<RecipeCategory>>((ref) {
  return ref.watch(recipeCategoryRepositoryProvider).getCategories();
});

class RecipeCategoriesScreen extends ConsumerStatefulWidget {
  const RecipeCategoriesScreen({super.key});

  @override
  ConsumerState<RecipeCategoriesScreen> createState() =>
      _RecipeCategoriesScreenState();
}

class _RecipeCategoriesScreenState
    extends ConsumerState<RecipeCategoriesScreen> {
  List<RecipeCategory>? _local;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(recipeCategoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rezept-Kategorien')),
      body: categoriesAsync.when(
        data: (cats) {
          _local ??= [...cats];
          final list = _local!;
          if (cats.isNotEmpty && list.length != cats.length) {
            _local = [...cats];
          }
          return list.isEmpty
              ? const EmptyState(
                  icon: Icons.restaurant_menu,
                  title: 'Keine Rezept-Kategorien')
              : RefreshIndicator(
                  onRefresh: () async {
                    _local = null;
                    ref.invalidate(recipeCategoriesListProvider);
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
                            .read(recipeCategoryRepositoryProvider)
                            .reorderCategories(list.map((c) => c.id).toList());
                        ref.invalidate(recipeCategoriesListProvider);
                      } on ApiException catch (e) {
                        if (mounted) {
                          showAppToast(context,
                              message: e.message, type: ToastType.error);
                        }
                      }
                    },
                    itemBuilder: (_, i) => _RecipeCategoryTile(
                      key: ValueKey('rcat_${list[i].id}'),
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
        heroTag: 'addRecipeCategory',
        onPressed: () async {
          await _showForm(context, ref);
          _local = null;
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref,
      {RecipeCategory? category}) async {
    final nameController =
        TextEditingController(text: category?.name ?? '');
    final colorController =
        TextEditingController(text: category?.color ?? '#1565C0');
    final isEdit = category != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Kategorie bearbeiten' : 'Neue Rezept-Kategorie'),
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
        'color': colorController.text.trim(),
      };
      final repo = ref.read(recipeCategoryRepositoryProvider);
      if (isEdit) {
        await repo.updateCategory(category.id, data);
      } else {
        await repo.createCategory(data);
      }
      ref.invalidate(recipeCategoriesListProvider);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, RecipeCategory category) async {
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
      await ref
          .read(recipeCategoryRepositoryProvider)
          .deleteCategory(category.id);
      refreshAfterMutation(ref);
    } on ApiException catch (e) {
      if (context.mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    }
  }
}

class _RecipeCategoryTile extends StatelessWidget {
  final int index;
  final RecipeCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecipeCategoryTile({
    super.key,
    required this.index,
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  Color _parseColor() {
    try {
      return Color(int.parse(
          'FF${category.color.replaceFirst('#', '')}',
          radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 16),
      title: Text('${category.icon} ${category.name}'),
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

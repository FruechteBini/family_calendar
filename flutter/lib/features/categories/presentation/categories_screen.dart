import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/category_repository.dart';
import '../domain/category.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';

final categoriesListProvider = FutureProvider<List<Category>>((ref) {
  return ref.watch(categoryRepositoryProvider).getCategories();
});

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kategorien')),
      body: categoriesAsync.when(
        data: (cats) => cats.isEmpty
            ? const EmptyState(icon: Icons.label_outline, title: 'Keine Kategorien')
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(categoriesListProvider),
                child: ListView.builder(
                  itemCount: cats.length,
                  itemBuilder: (_, i) => _CategoryTile(
                    category: cats[i],
                    onEdit: () => _showForm(context, ref, category: cats[i]),
                    onDelete: () => _delete(context, ref, cats[i]),
                  ),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Fehler', subtitle: e.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addCategory',
        onPressed: () => _showForm(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, WidgetRef ref, {Category? category}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final colorController = TextEditingController(text: category?.color ?? '#1565C0');
    final isEdit = category != null;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Kategorie bearbeiten' : 'Neue Kategorie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.label_outline))),
            const SizedBox(height: 12),
            TextField(controller: colorController, decoration: const InputDecoration(labelText: 'Farbe (Hex)', prefixIcon: Icon(Icons.palette_outlined), hintText: '#1565C0')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEdit ? 'Speichern' : 'Erstellen')),
        ],
      ),
    );
    if (result != true || nameController.text.trim().isEmpty) return;
    try {
      final data = {'name': nameController.text.trim(), 'color': colorController.text.trim()};
      final repo = ref.read(categoryRepositoryProvider);
      if (isEdit) {
        await repo.updateCategory(category!.id, data);
      } else {
        await repo.createCategory(data);
      }
      ref.invalidate(categoriesListProvider);
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kategorie loeschen?'),
        content: Text('"${category.name}" loeschen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Loeschen')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(categoryRepositoryProvider).deleteCategory(category.id);
      ref.invalidate(categoriesListProvider);
    } on ApiException catch (e) {
      if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryTile({required this.category, required this.onEdit, required this.onDelete});

  Color _parseColor() {
    if (category.color == null) return Colors.grey;
    try {
      return Color(int.parse('FF${category.color!.replaceFirst('#', '')}', radix: 16));
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
          IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit),
          IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: onDelete),
        ],
      ),
    );
  }
}

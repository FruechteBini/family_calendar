import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/cookidoo_repository.dart';
import '../domain/cookidoo.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';

class CookidooBrowser extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final VoidCallback onImported;

  const CookidooBrowser({super.key, required this.scrollController, required this.onImported});

  @override
  ConsumerState<CookidooBrowser> createState() => _CookidooBrowserState();
}

class _CookidooBrowserState extends ConsumerState<CookidooBrowser> {
  CookidooStatus? _status;
  List<CookidooCollection>? _collections;
  CookidooCollection? _selectedCollection;
  CookidooRecipe? _selectedRecipe;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(cookidooRepositoryProvider);
      _status = await repo.getStatus();
      if (_status!.available) {
        _collections = await repo.getCollections();
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _importRecipe(String cookidooId) async {
    try {
      await ref.read(cookidooRepositoryProvider).importRecipe(cookidooId);
      if (mounted) {
        showAppToast(context, message: 'Rezept importiert', type: ToastType.success);
        widget.onImported();
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_status?.available != true) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text('Cookidoo nicht verfuegbar', style: theme.textTheme.titleMedium),
            if (_status?.message != null) ...[
              const SizedBox(height: 8),
              Text(_status!.message!, style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      );
    }

    if (_selectedRecipe != null) {
      return _buildRecipeDetail(theme);
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (_selectedCollection != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => setState(() => _selectedCollection = null),
                ),
              Expanded(
                child: Text(
                  _selectedCollection?.name ?? 'Cookidoo Collections',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _collections == null || _collections!.isEmpty
              ? const Center(child: Text('Keine Collections gefunden'))
              : ListView.builder(
                  controller: widget.scrollController,
                  itemCount: _collections!.length,
                  itemBuilder: (_, i) {
                    final col = _collections![i];
                    return ListTile(
                      leading: const Icon(Icons.collections_bookmark),
                      title: Text(col.name),
                      subtitle: Text('${col.recipeCount} Rezepte'),
                      onTap: () async {
                        final recipe = await _pickRecipeFromCollection(col);
                        if (recipe != null) {
                          setState(() => _selectedRecipe = recipe);
                        }
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRecipeDetail(ThemeData theme) {
    final recipe = _selectedRecipe!;
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedRecipe = null)),
              Expanded(child: Text(recipe.name, style: theme.textTheme.titleMedium)),
            ],
          ),
          if (recipe.description != null) ...[
            const SizedBox(height: 8),
            Text(recipe.description!),
          ],
          if (recipe.ingredients.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Zutaten', style: theme.textTheme.titleSmall),
            ...recipe.ingredients.map((i) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('- $i', style: theme.textTheme.bodySmall),
                )),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _importRecipe(recipe.id),
              icon: const Icon(Icons.download),
              label: const Text('Rezept importieren'),
            ),
          ),
        ],
      ),
    );
  }

  Future<CookidooRecipe?> _pickRecipeFromCollection(CookidooCollection col) async {
    // In a full implementation, we'd load recipes from the collection.
    // For now, show a dialog asking for recipe ID.
    final controller = TextEditingController();
    final recipeId = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Rezept aus "${col.name}"'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Cookidoo Rezept-ID'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Laden')),
        ],
      ),
    );
    if (recipeId == null || recipeId.isEmpty) return null;
    try {
      return await ref.read(cookidooRepositoryProvider).getRecipe(recipeId);
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
      return null;
    }
  }
}

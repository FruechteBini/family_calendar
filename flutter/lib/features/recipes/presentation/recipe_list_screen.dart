import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import '../../cookidoo/presentation/cookidoo_browser.dart';
import '../../../shared/widgets/difficulty_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../core/api/api_client.dart';
import 'recipe_form_dialog.dart';

final recipesProvider = FutureProvider<List<Recipe>>((ref) {
  return ref.watch(recipeRepositoryProvider).getRecipes();
});

final recipeSuggestionsProvider = FutureProvider<List<Recipe>>((ref) {
  return ref.watch(recipeRepositoryProvider).getSuggestions();
});

class RecipeListScreen extends ConsumerStatefulWidget {
  const RecipeListScreen({super.key});

  @override
  ConsumerState<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends ConsumerState<RecipeListScreen> {
  String _search = '';
  String? _difficultyFilter;

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(hintText: 'Rezept suchen...', prefixIcon: Icon(Icons.search), isDense: true),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String?>(
                icon: const Icon(Icons.filter_list),
                onSelected: (v) => setState(() => _difficultyFilter = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('Alle')),
                  const PopupMenuItem(value: 'einfach', child: DifficultyBadge(difficulty: 'einfach')),
                  const PopupMenuItem(value: 'mittel', child: DifficultyBadge(difficulty: 'mittel')),
                  const PopupMenuItem(value: 'schwer', child: DifficultyBadge(difficulty: 'schwer')),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.cloud_download_outlined),
                onPressed: () => _openCookidoo(context),
                tooltip: 'Cookidoo importieren',
              ),
            ],
          ),
        ),
        Expanded(
          child: recipesAsync.when(
            data: (recipes) {
              var filtered = recipes.where((r) => r.name.toLowerCase().contains(_search.toLowerCase()));
              if (_difficultyFilter != null) {
                filtered = filtered.where((r) => r.difficulty == _difficultyFilter);
              }
              final list = filtered.toList();
              if (list.isEmpty) {
                return const EmptyState(icon: Icons.menu_book_outlined, title: 'Keine Rezepte', subtitle: 'Erstelle ein neues Rezept oder importiere von Cookidoo');
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(recipesProvider),
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => _RecipeCard(
                    recipe: list[i],
                    onTap: () => _showForm(recipe: list[i]),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Fehler', subtitle: e.toString()),
          ),
        ),
        // URL Import bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Neues Rezept'),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _importFromUrl(),
                icon: const Icon(Icons.link),
                label: const Text('URL Import'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showForm({Recipe? recipe}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => RecipeFormDialog(recipe: recipe),
    );
    if (result == true) ref.invalidate(recipesProvider);
  }

  Future<void> _importFromUrl() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept von URL importieren'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            hintText: 'https://www.chefkoch.de/rezepte/...',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
          FilledButton(onPressed: () => Navigator.pop(ctx, urlController.text.trim()), child: const Text('Importieren')),
        ],
      ),
    );
    if (url == null || url.isEmpty) return;
    try {
      final preview = await ref.read(recipeRepositoryProvider).parseUrl(url);
      if (mounted) {
        await showDialog(
          context: context,
          builder: (ctx) => RecipeFormDialog(recipe: preview),
        );
        ref.invalidate(recipesProvider);
      }
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, message: e.message, type: ToastType.error);
    } catch (e) {
      if (mounted) showAppToast(context, message: 'Fehler beim Parsen: $e', type: ToastType.error);
    }
  }

  void _openCookidoo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => CookidooBrowser(
          scrollController: controller,
          onImported: () => ref.invalidate(recipesProvider),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (recipe.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: recipe.imageUrl!,
                    width: 60, height: 60,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.restaurant, size: 30),
                  ),
                )
              else
                Container(
                  width: 60, height: 60,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, size: 30),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recipe.name, style: theme.textTheme.titleSmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        DifficultyBadge(difficulty: recipe.difficulty),
                        if (recipe.prepTime != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.schedule, size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 2),
                          Text('${recipe.prepTime} Min.', style: theme.textTheme.bodySmall),
                        ],
                        if (recipe.isCookidoo) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.cloud, size: 14, color: theme.colorScheme.outline),
                        ],
                      ],
                    ),
                    if (recipe.lastCooked != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Zuletzt: ${_daysSince(recipe.lastCooked!)} Tage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _daysSince(recipe.lastCooked!) > 28 ? Colors.orange : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _daysSince(DateTime date) => DateTime.now().difference(date).inDays;
}

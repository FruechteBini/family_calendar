import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../shared/widgets/difficulty_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/recipe_thumbnail.dart';
import '../../../shared/widgets/toast.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import 'recipe_form_dialog.dart';

final recipeDetailProvider = FutureProvider.family<Recipe, int>((ref, id) async {
  return ref.watch(recipeRepositoryProvider).getRecipe(id);
});

class RecipeDetailScreen extends ConsumerWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  Future<void> _edit(BuildContext context, WidgetRef ref, Recipe recipe) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => RecipeFormDialog(recipe: recipe),
    );
    if (changed == true) {
      ref.invalidate(recipeDetailProvider(recipeId));
      if (context.mounted) showAppToast(context, message: 'Gespeichert', type: ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Rezept'),
        actions: [
          recipeAsync.maybeWhen(
            data: (r) => IconButton(
              tooltip: 'Bearbeiten',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(context, ref, r),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => EmptyState(
          icon: Icons.menu_book_outlined,
          title: 'Rezept konnte nicht geladen werden',
          subtitle: err is ApiException ? err.message : err.toString(),
        ),
        data: (r) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecipeThumbnail(
                    imageUrl: r.imageUrl,
                    size: 84,
                    borderRadius: 16,
                    fallback: const Icon(Icons.restaurant, size: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            DifficultyBadge(difficulty: r.difficulty),
                            if (r.prepTime != null)
                              _Chip(
                                icon: Icons.schedule,
                                label: '${r.prepTime} Min',
                              ),
                            if (r.isCookidoo)
                              const _Chip(
                                icon: Icons.cloud,
                                label: 'Cookidoo',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (r.description != null && r.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(r.description!, style: theme.textTheme.bodyMedium),
              ],
              const SizedBox(height: 16),
              Text('Zutaten', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (r.ingredients.isEmpty)
                Text('Keine Zutaten hinterlegt.', style: theme.textTheme.bodySmall)
              else
                ...r.ingredients.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• ${_ingredientText(i)}', style: theme.textTheme.bodyMedium),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static String _ingredientText(Ingredient i) {
    final amount = i.amount;
    final unit = i.unit;
    final prefix = amount == null
        ? null
        : unit == null || unit.isEmpty
            ? amount.toString()
            : '$amount $unit';
    return prefix == null ? i.name : '$prefix ${i.name}';
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(label, style: theme.textTheme.labelMedium),
        ],
      ),
    );
  }
}


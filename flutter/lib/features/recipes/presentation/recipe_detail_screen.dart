import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/sync/sync_service.dart';
import '../../cookidoo/data/cookidoo_repository.dart';
import '../../../shared/widgets/difficulty_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/recipe_thumbnail.dart';
import '../../../shared/widgets/toast.dart';
import '../data/recipe_repository.dart';
import '../domain/recipe.dart';
import 'recipe_form_dialog.dart';
import 'recipe_list_screen.dart';

final recipeDetailProvider = FutureProvider.family<Recipe, int>((ref, id) async {
  return ref.watch(recipeRepositoryProvider).getRecipe(id);
});

class RecipeDetailScreen extends ConsumerStatefulWidget {
  final int recipeId;

  const RecipeDetailScreen({super.key, required this.recipeId});

  @override
  ConsumerState<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends ConsumerState<RecipeDetailScreen> {
  bool _cookidooPlanning = false;

  Future<void> _edit(BuildContext context, Recipe recipe) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => RecipeFormDialog(recipe: recipe),
    );
    if (changed == true) {
      ref.invalidate(recipeDetailProvider(widget.recipeId));
      ref.invalidate(recipesProvider);
      notifyDataMutated(ref);
      if (context.mounted) {
        showAppToast(context, message: 'Gespeichert', type: ToastType.success);
      }
    }
  }

  Future<void> _planTodayOnCookidoo(String cookidooId, String recipeName) async {
    setState(() => _cookidooPlanning = true);
    try {
      await ref.read(cookidooRepositoryProvider).planRecipesOnCookidooDay([cookidooId]);
      if (mounted) {
        showAppToast(
          context,
          message: '„$recipeName“ ist in Cookidoo für heute eingeplant',
          type: ToastType.success,
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, message: e.toString(), type: ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _cookidooPlanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Rezept'),
        actions: [
          recipeAsync.maybeWhen(
            data: (r) => IconButton(
              tooltip: 'Bearbeiten',
              icon: const Icon(Icons.edit),
              onPressed: () => _edit(context, r),
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
          final cid = r.cookidooId;
          final canPlanCookidoo = cid != null && cid.trim().isNotEmpty;
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
              if (canPlanCookidoo) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: _cookidooPlanning
                      ? null
                      : () => _planTodayOnCookidoo(cid.trim(), r.name),
                  icon: _cookidooPlanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restaurant_menu),
                  label: const Text('Heute kochen (Cookidoo)'),
                ),
                const SizedBox(height: 6),
                Text(
                  'Trägt das Rezept in Cookidoo „Mein Tag“ ein – synchron mit Thermomix, wenn verbunden.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (r.description != null && r.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Beschreibung', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
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
              if (r.instructions != null && r.instructions!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Zubereitung', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(r.instructions!, style: theme.textTheme.bodyMedium),
              ],
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

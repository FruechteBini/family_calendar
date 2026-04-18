import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/recipe_category_repository.dart';
import '../data/recipe_repository.dart';
import '../data/recipe_tag_repository.dart';
import '../domain/recipe.dart';
import '../domain/recipe_tag.dart';
import '../../cookidoo/presentation/cookidoo_browser.dart';
import '../../../shared/widgets/difficulty_badge.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/labeled_multiline_field.dart';
import '../../../shared/widgets/recipe_thumbnail.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../core/api/api_client.dart';
import 'ai_categorize_sheet.dart';
import 'recipe_categories_screen.dart';
import 'recipe_form_dialog.dart';

final recipeCategoryFilterProvider = StateProvider<int?>((ref) => null);
final recipeTagFilterSetProvider = StateProvider<Set<int>>((ref) => {});

final recipeTagsForFilterProvider = FutureProvider<List<RecipeTag>>((ref) {
  return ref.watch(recipeTagRepositoryProvider).getTags();
});

final recipesProvider = FutureProvider<List<Recipe>>((ref) async {
  final catId = ref.watch(recipeCategoryFilterProvider);
  final tags = ref.watch(recipeTagFilterSetProvider);
  final repo = ref.read(recipeRepositoryProvider);
  if (tags.length == 1) {
    return repo.getRecipes(recipeCategoryId: catId, tagId: tags.first);
  }
  final list = await repo.getRecipes(recipeCategoryId: catId);
  if (tags.isEmpty) return list;
  return list
      .where(
          (r) => tags.every((tid) => r.tags.any((x) => x.id == tid)))
      .toList();
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

  Future<void> _showAiCategorize() async {
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const RecipeAiCategorizeSheet(),
    );
    if (applied == true && mounted) {
      ref.invalidate(recipesProvider);
      ref.invalidate(recipeCategoriesListProvider);
      ref.invalidate(recipeTagsForFilterProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);
    final categoriesAsync = ref.watch(recipeCategoriesListProvider);
    final tagsAsync = ref.watch(recipeTagsForFilterProvider);
    final selectedCategoryId = ref.watch(recipeCategoryFilterProvider);
    final selectedTagIds = ref.watch(recipeTagFilterSetProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(ScreenHeader.horizontalPadding, 4, ScreenHeader.horizontalPadding, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Rezept suchen...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'KI sortieren',
                onPressed: _showAiCategorize,
                icon: const Icon(Icons.auto_awesome),
              ),
              PopupMenuButton<String?>(
                icon: const Icon(Icons.filter_list),
                onSelected: (v) => setState(() => _difficultyFilter = v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('Alle')),
                  const PopupMenuItem(
                      value: 'einfach',
                      child: DifficultyBadge(difficulty: 'einfach')),
                  const PopupMenuItem(
                      value: 'mittel',
                      child: DifficultyBadge(difficulty: 'mittel')),
                  const PopupMenuItem(
                      value: 'schwer',
                      child: DifficultyBadge(difficulty: 'schwer')),
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
        categoriesAsync.when(
          data: (cats) {
            final tabs = <Widget>[
              const Tab(text: 'Alle'),
              ...cats.map((c) => Tab(text: c.name)),
            ];
            final initialIndex = () {
              if (selectedCategoryId == null) return 0;
              final idx = cats.indexWhere((c) => c.id == selectedCategoryId);
              return idx >= 0 ? idx + 1 : 0;
            }();

            Future<void> openReorderSheet() async {
              final repo = ref.read(recipeCategoryRepositoryProvider);
              final local = [...cats];
              await showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                isScrollControlled: true,
                builder: (ctx) => StatefulBuilder(
                  builder: (context, setModalState) {
                    return SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kategorien anordnen',
                              style: Theme.of(ctx).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxHeight: 420),
                              child: ReorderableListView.builder(
                                shrinkWrap: true,
                                buildDefaultDragHandles: false,
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: local.length,
                                onReorder: (oldIndex, newIndex) async {
                                  if (newIndex > oldIndex) newIndex -= 1;
                                  setModalState(() {
                                    final item = local.removeAt(oldIndex);
                                    local.insert(newIndex, item);
                                  });
                                  try {
                                    await repo.reorderCategories(
                                        local.map((c) => c.id).toList());
                                    ref.invalidate(recipeCategoriesListProvider);
                                  } on ApiException catch (e) {
                                    if (ctx.mounted) {
                                      showAppToast(ctx,
                                          message: e.message,
                                          type: ToastType.error);
                                    }
                                  }
                                },
                                itemBuilder: (_, i) => ListTile(
                                  key: ValueKey('reorder_rcat_${local[i].id}'),
                                  title: Text(local[i].name),
                                  trailing: ReorderableDragStartListener(
                                    index: i,
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: FilledButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Fertig'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }

            Future<void> openManageCategories() async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const RecipeCategoriesScreen(),
                ),
              );
              ref.invalidate(recipeCategoriesListProvider);
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: DefaultTabController(
                      length: tabs.length,
                      initialIndex: initialIndex,
                      child: Builder(
                        builder: (context) => TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          onTap: (i) {
                            if (i == 0) {
                              ref
                                  .read(recipeCategoryFilterProvider.notifier)
                                  .state = null;
                            } else {
                              ref
                                  .read(recipeCategoryFilterProvider.notifier)
                                  .state = cats[i - 1].id;
                            }
                            ref.invalidate(recipesProvider);
                          },
                          tabs: tabs,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kategorien verwalten',
                    onPressed: openManageCategories,
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Kategorien anordnen',
                    onPressed: openReorderSheet,
                    icon: const Icon(Icons.drag_handle),
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(height: 8),
          error: (_, __) => const SizedBox(height: 8),
        ),
        tagsAsync.when(
          data: (tags) {
            if (tags.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: tags.length,
                itemBuilder: (_, i) {
                  final t = tags[i];
                  final sel = selectedTagIds.contains(t.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6, bottom: 6),
                    child: FilterChip(
                      label: Text(t.name),
                      selected: sel,
                      onSelected: (v) {
                        final next = {...selectedTagIds};
                        if (v) {
                          next.add(t.id);
                        } else {
                          next.remove(t.id);
                        }
                        ref.read(recipeTagFilterSetProvider.notifier).state =
                            next;
                        ref.invalidate(recipesProvider);
                      },
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Expanded(
          child: recipesAsync.when(
            data: (recipes) {
              var filtered = recipes.where(
                  (r) => r.name.toLowerCase().contains(_search.toLowerCase()));
              if (_difficultyFilter != null) {
                filtered =
                    filtered.where((r) => r.difficulty == _difficultyFilter);
              }
              final list = filtered.toList();
              if (list.isEmpty) {
                return const EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'Keine Rezepte',
                  subtitle:
                      'Erstelle ein neues Rezept, importiere von Cookidoo oder passe Filter an',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(recipesProvider);
                  ref.invalidate(recipeCategoriesListProvider);
                  ref.invalidate(recipeTagsForFilterProvider);
                },
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) => _RecipeCard(
                    recipe: list[i],
                    onTap: () => context.push('/recipes/${list[i].id}'),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Fehler',
                subtitle: e.toString()),
          ),
        ),
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
    if (result == true) {
      ref.invalidate(recipesProvider);
      ref.invalidate(recipeTagsForFilterProvider);
      ref.invalidate(recipeCategoriesListProvider);
    }
  }

  Future<void> _importFromUrl() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rezept von URL importieren'),
        content: LabeledOutlineTextField(
          label: 'Rezept-URL',
          controller: urlController,
          hintText: 'https://www.chefkoch.de/rezepte/...',
          prefixIcon: const Icon(Icons.link),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Abbrechen')),
          FilledButton(
              onPressed: () =>
                  Navigator.pop(ctx, urlController.text.trim()),
              child: const Text('Importieren')),
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
      if (mounted) {
        showAppToast(context, message: e.message, type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context,
            message: 'Fehler beim Parsen: $e', type: ToastType.error);
      }
    }
  }

  void _openCookidoo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
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

class _RecipeCard extends ConsumerWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipeCard({required this.recipe, required this.onTap});

  Color? _categoryColor() {
    final hex = recipe.categoryColor;
    if (hex == null || hex.length < 4) return null;
    try {
      return Color(
          int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cc = _categoryColor();
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cc != null) ...[
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: cc,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              RecipeThumbnail(
                imageUrl: recipe.imageUrl,
                size: 60,
                borderRadius: 8,
                fallback: const Icon(Icons.restaurant, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (recipe.categoryName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        recipe.categoryName!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        DifficultyBadge(difficulty: recipe.difficulty),
                        if (recipe.prepTime != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.schedule,
                              size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 2),
                          Text(
                            '${recipe.prepTime} Min.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                        if (recipe.isCookidoo) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.cloud,
                              size: 14, color: theme.colorScheme.outline),
                        ],
                      ],
                    ),
                    if (recipe.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: recipe.tags
                            .take(4)
                            .map(
                              (t) => Chip(
                                label: Text(
                                  t.name,
                                  style: theme.textTheme.labelSmall,
                                ),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    if (recipe.lastCooked != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Zuletzt: ${_daysSince(recipe.lastCooked!)} Tage',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: _daysSince(recipe.lastCooked!) > 28
                              ? Colors.orange
                              : theme.colorScheme.outline,
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

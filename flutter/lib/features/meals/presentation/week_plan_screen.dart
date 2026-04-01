import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/meal_repository.dart';
import '../domain/meal_plan.dart';
import '../../recipes/data/recipe_repository.dart';
import '../../recipes/domain/recipe.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/utils/date_utils.dart' as utils;
import '../../../core/api/api_client.dart';

final weekOffsetProvider = StateProvider<int>((ref) => 0);

final weekPlanProvider = FutureProvider<MealPlan>((ref) {
  final offset = ref.watch(weekOffsetProvider);
  return ref.watch(mealRepositoryProvider).getWeekPlan(weekOffset: offset);
});

final cookingHistoryProvider = FutureProvider<List<CookingHistoryEntry>>((ref) {
  return ref.watch(recipeRepositoryProvider).getHistory();
});

class WeekPlanScreen extends ConsumerWidget {
  const WeekPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(weekPlanProvider);
    final weekOffset = ref.watch(weekOffsetProvider);
    final theme = Theme.of(context);

    final weekStart = utils.AppDateUtils.startOfWeek(
      DateTime.now().add(Duration(days: weekOffset * 7)),
    );
    final weekDays = utils.AppDateUtils.weekDays(weekStart);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => ref.read(weekOffsetProvider.notifier).state--,
              ),
              GestureDetector(
                onTap: () => ref.read(weekOffsetProvider.notifier).state = 0,
                child: Text(
                  '${utils.AppDateUtils.formatDate(weekStart)} - ${utils.AppDateUtils.formatDate(weekDays.last)}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => ref.read(weekOffsetProvider.notifier).state++,
              ),
            ],
          ),
        ),
        Expanded(
          child: planAsync.when(
            data: (plan) => RefreshIndicator(
              onRefresh: () async => ref.invalidate(weekPlanProvider),
              child: ListView.builder(
                itemCount: 7,
                itemBuilder: (_, i) {
                  final day = weekDays[i];
                  final dateKey = utils.AppDateUtils.toIsoDate(day);
                  final dayPlan = plan.days[dateKey];
                  final isToday = utils.AppDateUtils.isToday(day);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    color: isToday ? theme.colorScheme.primaryContainer.withOpacity(0.3) : null,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${utils.AppDateUtils.formatShortDay(day)} ${utils.AppDateUtils.formatDate(day)}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isToday ? FontWeight.bold : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _SlotCard(label: 'Mittag', slot: dayPlan?.lunch, date: dateKey, slotName: 'lunch', ref: ref, context: context)),
                              const SizedBox(width: 8),
                              Expanded(child: _SlotCard(label: 'Abend', slot: dayPlan?.dinner, date: dateKey, slotName: 'dinner', ref: ref, context: context)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(icon: Icons.error_outline, title: 'Fehler', subtitle: e.toString()),
          ),
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final String label;
  final MealSlot? slot;
  final String date;
  final String slotName;
  final WidgetRef ref;
  final BuildContext context;

  const _SlotCard({
    required this.label,
    this.slot,
    required this.date,
    required this.slotName,
    required this.ref,
    required this.context,
  });

  @override
  Widget build(BuildContext outerContext) {
    final theme = Theme.of(outerContext);
    final hasRecipe = slot?.recipeId != null;
    final isCooked = slot?.cooked ?? false;

    return InkWell(
      onTap: () => hasRecipe ? _showSlotActions(outerContext) : _assignSlot(outerContext),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          color: isCooked ? theme.colorScheme.primaryContainer.withOpacity(0.2) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 4),
            if (hasRecipe) ...[
              Text(slot!.recipeName ?? '?', style: theme.textTheme.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              if (isCooked) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: theme.colorScheme.primary),
                    if (slot!.rating != null) ...[
                      const SizedBox(width: 4),
                      ...List.generate(slot!.rating!, (_) => Icon(Icons.star, size: 12, color: Colors.amber)),
                    ],
                  ],
                ),
              ],
            ] else
              Text('+ Rezept', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
          ],
        ),
      ),
    );
  }

  void _assignSlot(BuildContext ctx) async {
    final recipes = await ref.read(recipeRepositoryProvider).getRecipes();
    if (!ctx.mounted) return;
    final recipe = await showDialog<Recipe>(
      context: ctx,
      builder: (_) => _RecipePickerDialog(recipes: recipes),
    );
    if (recipe == null) return;
    try {
      await ref.read(mealRepositoryProvider).setSlot(date, slotName, recipe.id);
      ref.invalidate(weekPlanProvider);
    } on ApiException catch (e) {
      if (ctx.mounted) showAppToast(ctx, message: e.message, type: ToastType.error);
    }
  }

  void _showSlotActions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!(slot?.cooked ?? false))
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Als gekocht markieren'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _markCooked(ctx);
                },
              ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Anderes Rezept'),
              onTap: () {
                Navigator.pop(ctx);
                _assignSlot(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Slot leeren', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                try {
                  await ref.read(mealRepositoryProvider).clearSlot(date, slotName);
                  ref.invalidate(weekPlanProvider);
                } on ApiException catch (e) {
                  if (ctx.mounted) showAppToast(ctx, message: e.message, type: ToastType.error);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _markCooked(BuildContext ctx) async {
    int? rating;
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setState) => AlertDialog(
          title: Text('${slot?.recipeName} bewerten'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => IconButton(
              icon: Icon(
                i < (rating ?? 0) ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 32,
              ),
              onPressed: () => setState(() => rating = i + 1),
            )),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Abbrechen')),
            FilledButton(onPressed: () => Navigator.pop(dlgCtx, true), child: const Text('Gekocht!')),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(mealRepositoryProvider).markCooked(date, slotName, rating: rating);
      ref.invalidate(weekPlanProvider);
      if (ctx.mounted) showAppToast(ctx, message: 'Als gekocht markiert', type: ToastType.success);
    } on ApiException catch (e) {
      if (ctx.mounted) showAppToast(ctx, message: e.message, type: ToastType.error);
    }
  }
}

class _RecipePickerDialog extends StatefulWidget {
  final List<Recipe> recipes;
  const _RecipePickerDialog({required this.recipes});

  @override
  State<_RecipePickerDialog> createState() => _RecipePickerDialogState();
}

class _RecipePickerDialogState extends State<_RecipePickerDialog> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.recipes.where((r) => r.name.toLowerCase().contains(_search.toLowerCase())).toList();
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(hintText: 'Rezept suchen...', prefixIcon: Icon(Icons.search)),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) => ListTile(
                  title: Text(filtered[i].name),
                  subtitle: filtered[i].difficulty != null ? Text(filtered[i].difficulty!) : null,
                  onTap: () => Navigator.pop(context, filtered[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
    final cs = theme.colorScheme;

    final weekStart = utils.AppDateUtils.startOfWeek(
      DateTime.now().add(Duration(days: weekOffset * 7)),
    );
    final weekDays = utils.AppDateUtils.weekDays(weekStart);

    return Column(
      children: [
        // Week navigation with tonal background
        Container(
          color: cs.surfaceContainerLow,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: cs.primary,
                onPressed: () => ref.read(weekOffsetProvider.notifier).state--,
              ),
              GestureDetector(
                onTap: () => ref.read(weekOffsetProvider.notifier).state = 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '${utils.AppDateUtils.formatDate(weekStart)} – ${utils.AppDateUtils.formatDate(weekDays.last)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01 * 14,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: cs.primary,
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
                padding: const EdgeInsets.only(top: 8, bottom: 24),
                itemCount: 7,
                itemBuilder: (_, i) {
                  final day = weekDays[i];
                  final dateKey = utils.AppDateUtils.toIsoDate(day);
                  final dayPlan = plan.days[dateKey];
                  final isToday = utils.AppDateUtils.isToday(day);
                  final isWeekend = day.weekday >= 6;

                  return _DayCard(
                    day: day,
                    dateKey: dateKey,
                    dayPlan: dayPlan,
                    isToday: isToday,
                    isWeekend: isWeekend,
                  );
                },
              ),
            ),
            loading: () => Center(
              child: CircularProgressIndicator(
                color: cs.primary,
                strokeWidth: 2,
              ),
            ),
            error: (e, _) => EmptyState(
              icon: Icons.error_outline,
              title: 'Fehler',
              subtitle: e.toString(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Individual day card with tonal nesting — no borders, only background shifts.
class _DayCard extends ConsumerWidget {
  final DateTime day;
  final String dateKey;
  final DayPlan? dayPlan;
  final bool isToday;
  final bool isWeekend;

  const _DayCard({
    required this.day,
    required this.dateKey,
    this.dayPlan,
    required this.isToday,
    required this.isWeekend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Tonal nesting: today uses a higher surface to stand out
    final cardColor = isToday
        ? cs.surfaceContainerHigh
        : isWeekend
            ? cs.surfaceContainerLow
            : cs.surfaceContainer;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day header with editorial typography
            Row(
              children: [
                if (isToday) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  utils.AppDateUtils.formatShortDay(day),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isToday ? cs.primary : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.05 * 11,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  utils.AppDateUtils.formatDate(day),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isToday ? cs.onSurface : cs.onSurfaceVariant,
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'HEUTE',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                        letterSpacing: 0.05 * 9,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SlotCard(
                    label: 'Mittag',
                    slot: dayPlan?.lunch,
                    date: dateKey,
                    slotName: 'lunch',
                    icon: Icons.wb_sunny_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SlotCard(
                    label: 'Abend',
                    slot: dayPlan?.dinner,
                    date: dateKey,
                    slotName: 'dinner',
                    icon: Icons.nightlight_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Slot card using tonal nesting — no borders, only background color shifts.
class _SlotCard extends ConsumerWidget {
  final String label;
  final MealSlot? slot;
  final String date;
  final String slotName;
  final IconData icon;

  const _SlotCard({
    required this.label,
    this.slot,
    required this.date,
    required this.slotName,
    required this.icon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasRecipe = slot?.recipeId != null;
    final isCooked = slot?.cooked ?? false;

    // "Recessed" look using surfaceContainerLowest inside surface cards
    final slotBg = isCooked
        ? cs.primaryContainer.withValues(alpha: 0.2)
        : hasRecipe
            ? cs.surfaceContainerHighest
            : cs.surfaceContainerLowest;

    return GestureDetector(
      onTap: () => hasRecipe
          ? _showSlotActions(context, ref)
          : _assignSlot(context, ref),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: slotBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot label with icon — uppercase tracking
            Row(
              children: [
                Icon(icon, size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.05 * 10,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasRecipe) ...[
              // Recipe image if available
              if (slot?.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: slot!.imageUrl!,
                    height: 80,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                slot!.recipeName ?? '?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (isCooked) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: cs.primary),
                    if (slot!.rating != null) ...[
                      const SizedBox(width: 4),
                      ...List.generate(
                        slot!.rating!,
                        (_) => Icon(Icons.star, size: 12, color: cs.secondary),
                      ),
                    ],
                  ],
                ),
              ],
            ] else
              // Empty slot — subtle add prompt
              Row(
                children: [
                  Icon(Icons.add_circle_outline, size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Text(
                    'Rezept',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _assignSlot(BuildContext ctx, WidgetRef ref) async {
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

  void _showSlotActions(BuildContext ctx, WidgetRef ref) {
    final theme = Theme.of(ctx);
    final cs = theme.colorScheme;

    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow.withValues(alpha: 0.6),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (slot?.recipeName != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Text(
                        slot!.recipeName!,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (!(slot?.cooked ?? false))
                    _SheetAction(
                      icon: Icons.check_circle_outline,
                      label: 'Als gekocht markieren',
                      iconColor: cs.primary,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await _markCooked(ctx, ref);
                      },
                    ),
                  _SheetAction(
                    icon: Icons.swap_horiz,
                    label: 'Anderes Rezept',
                    iconColor: cs.onSurfaceVariant,
                    onTap: () {
                      Navigator.pop(ctx);
                      _assignSlot(ctx, ref);
                    },
                  ),
                  _SheetAction(
                    icon: Icons.delete_outline,
                    label: 'Slot leeren',
                    iconColor: cs.error,
                    labelColor: cs.error,
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
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _markCooked(BuildContext ctx, WidgetRef ref) async {
    int? rating;
    final theme = Theme.of(ctx);
    final cs = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (dlgCtx, setState) => AlertDialog(
          backgroundColor: cs.surfaceContainerLow.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Text(
            '${slot?.recipeName} bewerten',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    i < (rating ?? 0) ? Icons.star : Icons.star_border,
                    color: cs.secondary,
                    size: 36,
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx, false),
              child: Text(
                'Abbrechen',
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cs.primaryContainer, cs.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: FilledButton(
                onPressed: () => Navigator.pop(dlgCtx, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                child: const Text('Gekocht!'),
              ),
            ),
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

/// Bottom sheet action with generous spacing — no dividers.
class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color? labelColor;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.labelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: labelColor ?? cs.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Glassmorphism recipe picker dialog
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final filtered = widget.recipes
        .where((r) => r.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Text(
                    'Rezept wählen',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.01 * 16,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rezept suchen...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: cs.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9999),
                        borderSide: BorderSide(
                          color: cs.primary.withValues(alpha: 0.4),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (_, i) => InkWell(
                      onTap: () => Navigator.pop(context, filtered[i]),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            // Recipe thumbnail
                            if (filtered[i].imageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: CachedNetworkImage(
                                  imageUrl: filtered[i].imageUrl!,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.restaurant, size: 20, color: cs.outline),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.restaurant, size: 20, color: cs.outline),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    filtered[i].name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (filtered[i].difficulty.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      filtered[i].difficulty,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, size: 20, color: cs.outline),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
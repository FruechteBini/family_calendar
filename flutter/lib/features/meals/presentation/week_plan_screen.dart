import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/recipe_thumbnail.dart';
import '../../../core/sync/sync_service.dart';
import '../../ai/presentation/ai_meal_plan_wizard.dart';
import '../../meals/data/meal_repository.dart';
import '../../recipes/domain/recipe.dart';
import '../../recipes/presentation/recipe_list_screen.dart';
import '../domain/meal_plan.dart';
import 'week_plan_provider.dart';

class WeekPlanScreen extends ConsumerWidget {
  const WeekPlanScreen({super.key});

  int _isoWeekNumber(DateTime date) {
    final dayOfYear = DateTime(date.year, date.month, date.day)
        .difference(DateTime(date.year, 1, 1))
        .inDays;
    final dow = date.weekday; // 1 = Monday
    final weekNumber = ((dayOfYear - dow + 10) / 7).floor();
    return weekNumber < 1
        ? _isoWeekNumber(DateTime(date.year - 1, 12, 31))
        : weekNumber;
  }

  DateTime _startOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = Monday
    return date.subtract(Duration(days: weekday - 1));
  }

  String _formatDateShort(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final weekStart = _startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 6));
    final kw = _isoWeekNumber(now);

    final weekPlanAsync = ref.watch(weekPlanProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(weekPlanProvider);
            ref.invalidate(recipeSuggestionsProvider);
            await ref.read(weekPlanProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppColors.spacing6,
                    AppColors.spacing6,
                    AppColors.spacing6,
                    AppColors.spacing4,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wochenplan Essen',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                      const SizedBox(height: AppColors.spacing2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'KW $kw · ${_formatDateShort(weekStart)} – ${_formatDateShort(weekEnd)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          _AiChip(
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Theme.of(context).colorScheme.surface,
                                useSafeArea: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => const AiMealPlanWizard(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              weekPlanAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppColors.spacing6),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(AppColors.spacing6),
                    child: EmptyState(
                      title: 'Wochenplan konnte nicht geladen werden',
                      subtitle: err is ApiException ? err.message : err.toString(),
                      icon: Icons.restaurant_menu,
                    ),
                  ),
                ),
                data: (plan) {
                  final days = _daysInWeek(plan, weekStart);
                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing6),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final day = days[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < days.length - 1 ? AppColors.spacing8 : AppColors.spacing6,
                            ),
                            child: _DaySection(day: day),
                          );
                        },
                        childCount: days.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppColors.spacing6)),
              const SliverToBoxAdapter(child: SizedBox(height: AppColors.spacing6)),
              SliverToBoxAdapter(child: _AiSuggestionsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  List<_UiDay> _daysInWeek(MealPlan plan, DateTime weekStart) {
    final out = <_UiDay>[];
    for (var i = 0; i < 7; i++) {
      final d = weekStart.add(Duration(days: i));
      final key = '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final dayPlan = plan.days[key];
      out.add(_UiDay(date: key, weekday: dayPlan?.weekday ?? _weekdayLabel(d), lunch: dayPlan?.lunch, dinner: dayPlan?.dinner));
    }
    return out;
  }

  String _weekdayLabel(DateTime d) {
    const names = [
      'Montag',
      'Dienstag',
      'Mittwoch',
      'Donnerstag',
      'Freitag',
      'Samstag',
      'Sonntag',
    ];
    return names[(d.weekday - 1).clamp(0, 6)];
  }
}

// ── Day Section Widget ──────────────────────────────────────────────────

class _UiDay {
  final String date; // YYYY-MM-DD
  final String weekday;
  final MealSlot? lunch;
  final MealSlot? dinner;

  const _UiDay({
    required this.date,
    required this.weekday,
    required this.lunch,
    required this.dinner,
  });
}

class _DaySection extends ConsumerWidget {
  final _UiDay day;

  const _DaySection({required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day label
        Padding(
          padding: const EdgeInsets.only(bottom: AppColors.spacing3),
          child: Text(
            day.weekday,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        _MealSlotTile(
          date: day.date,
          slot: 'lunch',
          label: 'MITTAGESSEN',
          meal: day.lunch,
        ),
        const SizedBox(height: AppColors.spacing3),
        _MealSlotTile(
          date: day.date,
          slot: 'dinner',
          label: 'ABENDESSEN',
          meal: day.dinner,
        ),
      ],
    );
  }
}

class _MealSlotTile extends ConsumerWidget {
  final String date; // YYYY-MM-DD
  final String slot; // lunch|dinner
  final String label;
  final MealSlot? meal;

  const _MealSlotTile({
    required this.date,
    required this.slot,
    required this.label,
    required this.meal,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasMeal = meal?.recipeId != null;

    if (!hasMeal) {
      return _EmptyMealSlot(
        label: label,
        onTap: () async {
          final chosen = await _pickRecipe(context, ref);
          if (chosen == null) return;
          try {
            await ref.read(mealRepositoryProvider).setSlot(date, slot, chosen.id);
            ref.invalidate(weekPlanProvider);
            ref.read(syncTickProvider.notifier).state++;
            // Ensure other screens (e.g. Today) see fresh data immediately.
            await ref.read(weekPlanProvider.future);
            if (context.mounted) {
              showAppToast(context, message: 'Eingetragen: ${chosen.name}', type: ToastType.success);
            }
          } on ApiException catch (e) {
            if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
          }
        },
      );
    }

    return _MealCard(
      label: label,
      title: meal?.recipeName ?? 'Unbekannt',
      imageUrl: meal?.imageUrl,
      cooked: meal?.cooked ?? false,
      onTap: () {
        final id = meal?.recipeId;
        if (id != null) {
          context.push('/recipes/$id');
        } else {
          _openMealActions(context, ref);
        }
      },
    );
  }

  Future<Recipe?> _pickRecipe(BuildContext context, WidgetRef ref) async {
    return showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final recipesAsync = ref.watch(recipesProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppColors.spacing4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Rezept wählen', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppColors.spacing3),
                SizedBox(
                  height: 420,
                  child: recipesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, _) => Center(
                      child: Text(err is ApiException ? err.message : err.toString()),
                    ),
                    data: (recipes) {
                      if (recipes.isEmpty) {
                        return const Center(child: Text('Keine Rezepte vorhanden.'));
                      }
                      return ListView.separated(
                        itemCount: recipes.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final r = recipes[i];
                          return ListTile(
                            leading: RecipeThumbnail(imageUrl: r.imageUrl, size: 48, borderRadius: 10),
                            title: Text(r.name),
                            subtitle: r.prepTime != null ? Text('${r.prepTime} Min') : null,
                            onTap: () => Navigator.pop(ctx, r),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMealActions(BuildContext context, WidgetRef ref) async {
    final cooked = meal?.cooked ?? false;
    final recipeName = meal?.recipeName ?? 'Unbekannt';

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(recipeName),
                subtitle: Text('$date · $label'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(cooked ? Icons.check_circle : Icons.check_circle_outline),
                title: Text(cooked ? 'Als ungekocht lassen' : 'Als gekocht markieren'),
                onTap: cooked
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        try {
                          await ref.read(mealRepositoryProvider).markCooked(date, slot);
                          ref.invalidate(weekPlanProvider);
                          ref.read(syncTickProvider.notifier).state++;
                          await ref.read(weekPlanProvider.future);
                          if (context.mounted) {
                            showAppToast(context, message: 'Als gekocht markiert', type: ToastType.success);
                          }
                        } on ApiException catch (e) {
                          if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
                        }
                      },
              ),
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Rezept ändern'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final chosen = await _pickRecipe(context, ref);
                  if (chosen == null) return;
                  try {
                    await ref.read(mealRepositoryProvider).setSlot(date, slot, chosen.id);
                    ref.invalidate(weekPlanProvider);
                    ref.read(syncTickProvider.notifier).state++;
                    await ref.read(weekPlanProvider.future);
                    if (context.mounted) {
                      showAppToast(context, message: 'Geaendert auf: ${chosen.name}', type: ToastType.success);
                    }
                  } on ApiException catch (e) {
                    if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Slot leeren'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await ref.read(mealRepositoryProvider).clearSlot(date, slot);
                    ref.invalidate(weekPlanProvider);
                    ref.read(syncTickProvider.notifier).state++;
                    await ref.read(weekPlanProvider.future);
                    if (context.mounted) showAppToast(context, message: 'Slot geleert', type: ToastType.success);
                  } on ApiException catch (e) {
                    if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _MealCard extends StatelessWidget {
  final String label;
  final String title;
  final String? imageUrl;
  final bool cooked;
  final VoidCallback onTap;

  const _MealCard({
    required this.label,
    required this.title,
    required this.imageUrl,
    required this.cooked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppColors.radiusDefault),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppColors.spacing4),
          child: Row(
            children: [
              RecipeThumbnail(
                imageUrl: imageUrl,
                size: 44,
                borderRadius: 12,
                fallback: Icon(
                  cooked ? Icons.check : Icons.restaurant,
                  color: cooked ? Theme.of(context).colorScheme.primary : AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppColors.spacing4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.08 * 11,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppColors.spacing2),
              const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMealSlot extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _EmptyMealSlot({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
          dashWidth: 8,
          dashSpace: 6,
          strokeWidth: 2,
          radius: AppColors.radiusDefault,
        ),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppColors.radiusDefault),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                size: 20,
                color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(width: AppColors.spacing2),
              Text(
                '$label hinzufügen',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dashed Border Painter ───────────────────────────────────────────────

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;
  final double strokeWidth;
  final double radius;

  _DashedBorderPainter({
    required this.color,
    required this.dashWidth,
    required this.dashSpace,
    required this.strokeWidth,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(radius),
    );

    // Draw dashed border along the rounded rectangle path
    final path = Path()..addRRect(rrect);

    // Use dash effect on the path
    final dashedPath = Path();
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final end = (distance + dashWidth).clamp(0.0, metric.length);
        dashedPath.addPath(
          metric.extractPath(distance, end),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.dashWidth != dashWidth ||
        oldDelegate.dashSpace != dashSpace ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.radius != radius;
  }
}

// ── AI Suggestions Section ──────────────────────────────────────────────

class _AiSuggestionsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final suggestionsAsync = ref.watch(recipeSuggestionsProvider);
        return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppColors.spacing6,
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppColors.spacing2),
              Text(
                'Vorschläge für dich',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppColors.spacing4),

        // Horizontal scroll of suggestion cards
        SizedBox(
          height: 260,
          child: suggestionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text(err is ApiException ? err.message : err.toString()),
            ),
            data: (recipes) {
              if (recipes.isEmpty) {
                return const Center(child: Text('Keine Vorschläge verfügbar.'));
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing6),
                itemCount: recipes.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppColors.spacing3),
                itemBuilder: (context, index) => _SuggestionCard(recipe: recipes[index]),
              );
            },
          ),
        ),
      ],
    );
      },
    );
  }
}

// ── Suggestion Card Widget ──────────────────────────────────────────────

class _SuggestionCard extends StatelessWidget {
  final Recipe recipe;

  const _SuggestionCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showAppToast(context, message: 'Tipp: Zum Eintragen einen Slot antippen.', type: ToastType.info);
      },
      child: Container(
        width: 200,
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppColors.radiusDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area with gradient overlay
            Expanded(
              flex: 140,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder image
                  Container(
                    color: AppColors.surfaceContainerHighest,
                    child: Center(
                      child: Icon(
                        Icons.dinner_dining,
                        size: 40,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                    ),
                  ),

                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.surfaceContainerHigh.withValues(alpha: 0.6),
                            AppColors.surfaceContainerHigh,
                          ],
                          stops: const [0.3, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Title overlaid on image bottom
                  Positioned(
                    left: AppColors.spacing4,
                    right: AppColors.spacing4,
                    bottom: AppColors.spacing3,
                    child: Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Tags area
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppColors.spacing4,
                AppColors.spacing2,
                AppColors.spacing4,
                AppColors.spacing4,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (recipe.prepTime != null)
                    _TagChip(text: '${recipe.prepTime} Min'),
                  _TagChip(text: recipe.difficulty),
                  if (recipe.isCookidoo) const _TagChip(text: 'Cookidoo'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppColors.radiusFull),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AiChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing4, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(AppColors.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.onPrimaryContainer),
            const SizedBox(width: 6),
            Text(
              'KI Vorschlag',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

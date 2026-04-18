import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/main_tab_swipe_scope.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/screen_header.dart';
import '../../../shared/widgets/toast.dart';
import '../../../shared/widgets/todo_completion_control.dart';
import '../../../shared/widgets/recipe_thumbnail.dart';
import '../../../core/sync/sync_service.dart';
import '../../calendar/data/event_repository.dart';
import '../../calendar/domain/event.dart';
import '../../meals/presentation/week_plan_provider.dart';
import '../../meals/domain/meal_plan.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/family_member.dart';
import '../../todos/data/todo_repository.dart';
import '../../todos/domain/todo.dart';

final todayEventsProvider = FutureProvider<List<Event>>((ref) async {
  ref.watch(syncTickProvider);
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
  return ref.watch(eventRepositoryProvider).getEvents(startDate: start, endDate: end);
});

final todayTodosProvider = FutureProvider<List<Todo>>((ref) async {
  ref.watch(syncTickProvider);
  final todos = await ref.watch(todoRepositoryProvider).getTodos(completed: false);
  todos.sort((a, b) {
    final ad = a.dueDate;
    final bd = b.dueDate;
    if (ad == null && bd == null) return 0;
    if (ad == null) return 1;
    if (bd == null) return -1;
    return ad.compareTo(bd);
  });
  return todos.take(8).toList();
});

final todayMembersProvider = FutureProvider<List<FamilyMember>>((ref) {
  return ref.watch(memberRepositoryProvider).getMembers();
});

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekPlanAsync = ref.watch(weekPlanProvider);
    final eventsAsync = ref.watch(todayEventsProvider);
    final todosAsync = ref.watch(todayTodosProvider);
    final membersAsync = ref.watch(todayMembersProvider);

    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: MainTabSwipeScope(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(weekPlanProvider);
              ref.invalidate(todayEventsProvider);
              ref.invalidate(todayTodosProvider);
              ref.invalidate(todayMembersProvider);
              await ref.read(todayEventsProvider.future);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: ScreenHeader.padding(bottom: AppColors.spacing2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heute',
                        style: ScreenHeader.titleStyle(context),
                      ),
                      const SizedBox(height: 6),
                      membersAsync.when(
                        loading: () => const SizedBox(height: 28),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (members) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: members.take(10).map((m) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Chip(
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  label: Text(
                                    '${m.emoji ?? '👤'} ${m.name}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ScreenHeader.horizontalPadding),
                  child: _SectionHeader(
                    title: 'Termine',
                    actionLabel: 'Alle sehen',
                    onAction: () => context.go('/calendar'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(ScreenHeader.horizontalPadding, AppColors.spacing2, ScreenHeader.horizontalPadding, 0),
                  child: eventsAsync.when(
                    loading: () => const SizedBox(
                      height: 36,
                      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                    ),
                    error: (err, _) => EmptyState(
                      icon: Icons.event_outlined,
                      title: 'Termine konnten nicht geladen werden',
                      subtitle: err is ApiException ? err.message : err.toString(),
                    ),
                    data: (events) {
                      if (events.isEmpty) {
                        return const _CompactEmptyHint('Keine Termine heute.');
                      }
                      return Column(
                        children: events.take(5).map((e) => _EventRow(event: e)).toList(),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppColors.spacing6)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ScreenHeader.horizontalPadding),
                  child: _SectionHeader(
                    title: 'Aufgaben',
                    actionLabel: 'Alle sehen',
                    onAction: () => context.go('/todos'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(ScreenHeader.horizontalPadding, AppColors.spacing2, ScreenHeader.horizontalPadding, 0),
                  child: todosAsync.when(
                    loading: () => const SizedBox(
                      height: 36,
                      child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
                    ),
                    error: (err, _) => EmptyState(
                      icon: Icons.checklist_outlined,
                      title: 'Aufgaben konnten nicht geladen werden',
                      subtitle: err is ApiException ? err.message : err.toString(),
                    ),
                    data: (todos) {
                      if (todos.isEmpty) {
                        return const _CompactEmptyHint('Keine offenen Aufgaben.');
                      }
                      return Column(
                        children: todos.map((t) => _TodoRow(todo: t)).toList(),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppColors.spacing6)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(ScreenHeader.horizontalPadding, 0, ScreenHeader.horizontalPadding, 120),
                  child: _TodayMealsSection(
                    weekPlanAsync: weekPlanAsync,
                    todayKey: todayKey,
                    onOpenMeals: () => context.go('/meals'),
                  ),
                ),
              ),
              ],
            ),
          ),
        ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: onAction,
          child: Text(actionLabel, style: Theme.of(context).textTheme.labelLarge),
        ),
      ],
    );
  }
}

/// Single line under section header when the list is empty (avoids tall EmptyState).
class _CompactEmptyHint extends StatelessWidget {
  final String text;
  const _CompactEmptyHint(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppColors.spacing1),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _TodayMealsSection extends ConsumerWidget {
  final AsyncValue<MealPlan> weekPlanAsync;
  final String todayKey;
  final VoidCallback onOpenMeals;

  const _TodayMealsSection({
    required this.weekPlanAsync,
    required this.todayKey,
    required this.onOpenMeals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return weekPlanAsync.when(
      loading: () => const SizedBox(
        height: 88,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => _PlannedMealCard(
        title: 'Wochenplan',
        slot: null,
        loadError: true,
        onOpenMeals: onOpenMeals,
      ),
      data: (plan) {
        final day = plan.days[todayKey];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PlannedMealCard(
              title: 'Mittagessen',
              slot: day?.lunch,
              loadError: false,
              onOpenMeals: onOpenMeals,
            ),
            const SizedBox(height: AppColors.spacing4),
            _PlannedMealCard(
              title: 'Abendessen',
              slot: day?.dinner,
              loadError: false,
              onOpenMeals: onOpenMeals,
            ),
          ],
        );
      },
    );
  }
}

class _PlannedMealCard extends StatelessWidget {
  final String title;
  final MealSlot? slot;
  final bool loadError;
  final VoidCallback onOpenMeals;

  const _PlannedMealCard({
    required this.title,
    required this.slot,
    required this.loadError,
    required this.onOpenMeals,
  });

  @override
  Widget build(BuildContext context) {
    if (loadError) {
      return Card(
        color: AppColors.surfaceContainerHigh,
        child: ListTile(
          title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: const Text('Wochenplan konnte nicht geladen werden'),
          trailing: PrimaryButton(label: 'Wochenplan öffnen', onPressed: onOpenMeals),
        ),
      );
    }

    final recipeId = slot?.recipeId;
    final hasRecipe = recipeId != null && recipeId > 0;
    final subtitle = hasRecipe
        ? 'Tippen, um das Rezept zu öffnen.'
        : 'Tippen, um ein Gericht einzutragen.';

    return Card(
      color: AppColors.surfaceContainerHigh,
      child: ListTile(
        onTap: () {
          if (hasRecipe) {
            context.push('/recipes/$recipeId');
          } else {
            onOpenMeals();
          }
        },
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: hasRecipe
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RecipeThumbnail(
                        imageUrl: slot?.imageUrl,
                        size: 44,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          slot?.recipeName ?? 'Unbekannt',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle),
                ],
              )
            : Text('Noch nichts geplant\n$subtitle'),
        trailing: !hasRecipe
            ? PrimaryButton(label: 'Zum Wochenplan', onPressed: onOpenMeals)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  final Event event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final time = event.allDay
        ? 'Ganztags'
        : '${event.startTime.hour.toString().padLeft(2, '0')}:${event.startTime.minute.toString().padLeft(2, '0')}';
    final hex = event.displayColorHex;
    Color? stripe;
    if (hex != null && hex.isNotEmpty) {
      final h = hex.replaceAll('#', '').trim();
      if (h.length == 6) {
        try {
          stripe = Color(int.parse('FF$h', radix: 16));
        } catch (_) {}
      }
    }
    stripe ??= Theme.of(context).colorScheme.primary;
    return Card(
      color: AppColors.surfaceContainerHigh,
      child: ListTile(
        leading: Container(
          width: 6,
          height: 40,
          decoration: BoxDecoration(
            color: stripe,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Text(event.title),
        subtitle: Text(time),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(event.detailLocation),
      ),
    );
  }
}

class _TodoRow extends ConsumerWidget {
  final Todo todo;
  const _TodoRow({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      color: AppColors.surfaceContainerHigh,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: TodoCompletionControl(
          completed: todo.completed,
          onToggle: () async {
            try {
              await ref.read(todoRepositoryProvider).completeTodo(todo.id, completed: !todo.completed);
              ref.invalidate(todayTodosProvider);
            } on ApiException catch (e) {
              if (context.mounted) showAppToast(context, message: e.message, type: ToastType.error);
            }
          },
        ),
        title: Text(todo.title),
        subtitle: todo.dueDate != null
            ? Text('Fällig: ${todo.dueDate!.day.toString().padLeft(2, '0')}.${todo.dueDate!.month.toString().padLeft(2, '0')}.')
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/todos/${todo.id}'),
      ),
    );
  }
}


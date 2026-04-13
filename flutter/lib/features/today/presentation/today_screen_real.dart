import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/toast.dart';
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
      body: SafeArea(
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
                  padding: const EdgeInsets.all(AppColors.spacing6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Heute',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              height: 1.15,
                            ),
                      ),
                      const SizedBox(height: AppColors.spacing2),
                      membersAsync.when(
                        loading: () => const SizedBox(height: 40),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (members) => SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: members.take(10).map((m) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Chip(
                                  label: Text('${m.emoji ?? '👤'} ${m.name}'),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing6),
                  child: _SectionHeader(
                    title: 'Termine',
                    actionLabel: 'Alle sehen',
                    onAction: () => context.go('/calendar'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppColors.spacing6, AppColors.spacing3, AppColors.spacing6, 0),
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
                  padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing6),
                  child: _SectionHeader(
                    title: 'Aufgaben',
                    actionLabel: 'Alle sehen',
                    onAction: () => context.go('/todos'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppColors.spacing6, AppColors.spacing3, AppColors.spacing6, 0),
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
                  padding: const EdgeInsets.fromLTRB(AppColors.spacing6, 0, AppColors.spacing6, 120),
                  child: _DinnerCard(
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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
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

class _DinnerCard extends ConsumerWidget {
  final AsyncValue weekPlanAsync;
  final String todayKey;
  final VoidCallback onOpenMeals;

  const _DinnerCard({
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
      error: (_, __) => _card(
        context,
        title: 'Abendessen',
        subtitle: 'Wochenplan konnte nicht geladen werden',
        cta: 'Wochenplan öffnen',
        showCta: true,
      ),
      data: (plan) {
        final dinner = plan.days[todayKey]?.dinner;
        final hasDinner = dinner?.recipeId != null;
        final subtitle = hasDinner
            ? 'Tippe für Aktionen.'
            : 'Tippe, um ein Gericht einzutragen.';
        return _card(
          context,
          title: 'Abendessen',
          dinner: dinner,
          subtitle: subtitle,
          cta: 'Zum Wochenplan',
          showCta: !hasDinner,
        );
      },
    );
  }

  Widget _card(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String cta,
    required bool showCta,
    MealSlot? dinner,
  }) {
    return Card(
      color: AppColors.surfaceContainerHigh,
      child: ListTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        subtitle: dinner?.recipeId != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      RecipeThumbnail(
                        imageUrl: dinner?.imageUrl,
                        size: 44,
                        borderRadius: 12,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dinner?.recipeName ?? 'Unbekannt',
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
        trailing: showCta ? PrimaryButton(label: cta, onPressed: onOpenMeals) : null,
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
    return Card(
      color: AppColors.surfaceContainerHigh,
      child: ListTile(
        leading: const Icon(Icons.event_outlined),
        title: Text(event.title),
        subtitle: Text(time),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/events/${event.id}'),
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
        leading: Checkbox(
          value: todo.completed,
          onChanged: (_) async {
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
      ),
    );
  }
}


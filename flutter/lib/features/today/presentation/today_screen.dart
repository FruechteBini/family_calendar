import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../calendar/data/event_repository.dart';
import '../../calendar/domain/event.dart';
import '../../todos/data/todo_repository.dart';
import '../../todos/domain/todo.dart';
import '../../meals/data/meal_repository.dart';
import '../../meals/domain/meal_plan.dart';
import '../../members/data/member_repository.dart';
import '../../members/domain/family_member.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/utils/date_utils.dart';

// ── Providers ──────────────────────────────────────────────────────────────

final _todayEventsProvider = FutureProvider<List<Event>>((ref) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  final end = start.add(const Duration(days: 1));
  return ref.watch(eventRepositoryProvider).getEvents(
        startDate: start,
        endDate: end,
      );
});

final _pendingTodosProvider = FutureProvider<List<Todo>>((ref) {
  return ref.watch(todoRepositoryProvider).getTodos(completed: false);
});

final _todayMealPlanProvider = FutureProvider<MealPlan>((ref) {
  return ref.watch(mealRepositoryProvider).getWeekPlan(weekOffset: 0);
});

final _membersProvider = FutureProvider<List<FamilyMember>>((ref) {
  return ref.watch(memberRepositoryProvider).getMembers();
});

// ── Color helpers ─────────────────────────────────────────────────────────

Color _parseColor(String? hex, Color fallback) {
  if (hex == null) return fallback;
  try {
    return Color(int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
  } catch (_) {
    return fallback;
  }
}

// Event bar colors cycle through primary / secondary / tertiary
final _barPalette = <Color Function(ColorScheme)>[
  (cs) => cs.primary,
  (cs) => cs.secondary,
  (cs) => cs.tertiary,
];

// ── Screen ────────────────────────────────────────────────────────────────

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final authState = ref.watch(authStateProvider);
    final familyName = authState.user?.familyId != null ? 'Familie' : 'Mein Kalender';

    final eventsAsync = ref.watch(_todayEventsProvider);
    final todosAsync = ref.watch(_pendingTodosProvider);
    final mealsAsync = ref.watch(_todayMealPlanProvider);
    final membersAsync = ref.watch(_membersProvider);

    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: cs.surface,
      body: RefreshIndicator(
        color: cs.primary,
        onRefresh: () async {
          ref.invalidate(_todayEventsProvider);
          ref.invalidate(_pendingTodosProvider);
          ref.invalidate(_todayMealPlanProvider);
          ref.invalidate(_membersProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Top App Bar ───────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: cs.surface,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: cs.primaryContainer, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: cs.primaryContainer.withOpacity(0.2),
                      child: Icon(Icons.person, color: cs.primaryContainer, size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    familyName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.mic, color: cs.primary),
                  onPressed: () {},
                ),
              ],
            ),

            // ── Family Ribbon ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: membersAsync.when(
                data: (members) =>
                    members.isEmpty ? const SizedBox.shrink() : _FamilyRibbon(members: members),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // ── "Heute" Section Title ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Heute',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => context.go('/calendar'),
                      child: Text(
                        'Alle Termine',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Timeline Events ───────────────────────────────────────────
            eventsAsync.when(
              data: (events) {
                final sorted = [...events]..sort((a, b) => a.startTime.compareTo(b.startTime));
                if (sorted.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.event_available, size: 40, color: cs.outlineVariant),
                            const SizedBox(height: 8),
                            Text(
                              'Keine Termine heute',
                              style: TextStyle(color: cs.outline, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  sliver: SliverList.builder(
                    itemCount: sorted.length,
                    itemBuilder: (context, i) => _TimelineEventCard(
                      event: sorted[i],
                      isLast: i == sorted.length - 1,
                      barColor: sorted[i].categoryColor != null
                          ? _parseColor(sorted[i].categoryColor, cs.primary)
                          : _barPalette[i % _barPalette.length](cs),
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // ── Bento Grid: Tasks + Dinner ────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Tasks
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _BentoTodosCard(todosAsync: todosAsync),
                        ),
                        const SizedBox(width: 12),
                        // Right: Dinner
                        SizedBox(
                          width: (constraints.maxWidth - 12) / 2,
                          child: _BentoDinnerCard(mealsAsync: mealsAsync, todayKey: todayKey),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }
}

// ── Family Ribbon ──────────────────────────────────────────────────────────

class _FamilyRibbon extends StatelessWidget {
  final List<FamilyMember> members;
  const _FamilyRibbon({required this.members});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: SizedBox(
        height: 68,
        child: Row(
          children: [
            // Overlapping avatars
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (int i = 0; i < members.length && i < 5; i++)
                    Positioned(
                      left: i * 42.0,
                      child: _MemberBubble(member: members[i], cs: cs),
                    ),
                  // Add button
                  Positioned(
                    left: (members.length.clamp(0, 5)) * 42.0 + 16,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => GoRouter.of(context).go('/members'),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surfaceContainerHighest,
                        ),
                        child: Icon(Icons.add, color: cs.onSurfaceVariant, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberBubble extends StatelessWidget {
  final FamilyMember member;
  final ColorScheme cs;
  const _MemberBubble({required this.member, required this.cs});

  @override
  Widget build(BuildContext context) {
    final avatarColor = _parseColor(member.color, cs.primaryContainer);
    final initial = member.name.isNotEmpty ? member.name[0].toUpperCase() : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: cs.surfaceContainerLowest, width: 4),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor.withOpacity(0.25),
                child: Text(
                  member.emoji ?? initial,
                  style: TextStyle(
                    fontSize: member.emoji != null ? 22 : 18,
                    fontWeight: FontWeight.w600,
                    color: avatarColor,
                  ),
                ),
              ),
              // Status dot
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surfaceContainerLowest, width: 2),
                  ),
                  child: Icon(
                    _memberIcon(member.name),
                    size: 10,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _memberIcon(String name) {
    // Simple heuristic for demo - real app could use role field
    final lower = name.toLowerCase();
    if (lower.contains('papa') || lower.contains('vater') || lower.contains('dad')) {
      return Icons.work;
    }
    if (lower.contains('mama') || lower.contains('mutter') || lower.contains('mom')) {
      return Icons.home;
    }
    return Icons.school;
  }
}

// ── Timeline Event Card ───────────────────────────────────────────────────

class _TimelineEventCard extends StatelessWidget {
  final Event event;
  final bool isLast;
  final Color barColor;

  const _TimelineEventCard({
    required this.event,
    required this.isLast,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final time = AppDateUtils.formatTime(event.startTime);

    // Person label
    final personLabel = event.members.isNotEmpty
        ? event.members.first.name.split(' ').first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Time + vertical line ──
          SizedBox(
            width: 48,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (!isLast) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: 3,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ── Right: Event card ──
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Row(
                children: [
                  // Left color bar
                  Container(width: 6, height: 72, color: barColor),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  event.title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: cs.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (personLabel != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: barColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    personLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: barColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                event.description != null && event.description!.isNotEmpty
                                    ? Icons.location_on
                                    : Icons.schedule,
                                size: 14,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  event.description != null && event.description!.isNotEmpty
                                      ? event.description!
                                      : event.allDay
                                          ? 'Ganztaegig'
                                          : '${AppDateUtils.formatTime(event.startTime)} - ${AppDateUtils.formatTime(event.endTime)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bento: Todos ──────────────────────────────────────────────────────────

class _BentoTodosCard extends StatelessWidget {
  final AsyncValue<List<Todo>> todosAsync;
  const _BentoTodosCard({required this.todosAsync});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Wichtige Aufgaben',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          todosAsync.when(
            data: (todos) {
              final items = todos.take(4).toList();
              if (items.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Alles erledigt!',
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                );
              }
              return Column(
                children: items.map((t) {
                  final isCompleted = t.completed;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCompleted
                                  ? cs.primaryContainer
                                  : cs.outlineVariant,
                              width: 2,
                            ),
                            color: isCompleted
                                ? cs.primaryContainer.withOpacity(0.2)
                                : null,
                          ),
                          child: isCompleted
                              ? Icon(Icons.check, size: 14, color: cs.primary)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isCompleted
                                  ? cs.onSurfaceVariant
                                  : cs.onSurface,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (_, __) => Text(
              'Fehler',
              style: TextStyle(color: cs.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bento: Dinner ─────────────────────────────────────────────────────────

class _BentoDinnerCard extends StatelessWidget {
  final AsyncValue<MealPlan> mealsAsync;
  final String todayKey;
  const _BentoDinnerCard({required this.mealsAsync, required this.todayKey});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surfaceContainerLow,
      ),
      child: mealsAsync.when(
        data: (plan) {
          final dinner = plan.days[todayKey]?.dinner;
          final mealName = dinner?.recipeName ?? 'Noch nicht geplant';
          final hasImage = dinner?.imageUrl != null;

          return Stack(
            fit: StackFit.passthrough,
            children: [
              // Background
              if (hasImage)
                Positioned.fill(
                  child: Image.network(
                    dinner!.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            cs.primaryContainer.withOpacity(0.3),
                            cs.primary.withOpacity(0.15),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.restaurant,
                            size: 48, color: cs.primary.withOpacity(0.3)),
                      ),
                    ),
                  ),
                )
              else
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          cs.primaryContainer.withOpacity(0.3),
                          cs.primary.withOpacity(0.15),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(Icons.restaurant,
                          size: 48, color: cs.primary.withOpacity(0.3)),
                    ),
                  ),
                ),

              // Gradient overlay + text
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: cs.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'ABENDESSEN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: cs.onSecondaryContainer,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        mealName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Zum Rezept',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: cs.primaryFixed,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.arrow_forward,
                              size: 12, color: cs.primaryFixed),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant, size: 18, color: cs.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Abendessen',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Noch nicht geplant',
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

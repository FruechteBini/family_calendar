import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../shared/widgets/hero_card.dart';
import '../../../shared/widgets/event_card.dart';
import '../../../shared/widgets/todo_item.dart';

// ── Screen ────────────────────────────────────────────────────────────────

/// Dashboard / Heute (Today) screen for "Familienherd".
///
/// Displays family status bubbles, today's dinner hero card,
/// calendar events, and task list. Uses sample/mock data.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          // ── Screen padding wrapper ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppColors.spacing6,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Top spacing (app bar is handled by app_shell.dart)
                const SizedBox(height: 16),

                // ── 2. FAMILY STATUS BUBBLES ─────────────────────────────
                _FamilyStatusBubbles(),

                const SizedBox(height: AppColors.spacing12),

                // ── 3. HEARTH HERO CARD (Today's Dinner) ────────────────
                HeroCard(
                  tagText: 'Heutiges Abendessen',
                  title: 'Spaghetti Bolognese',
                  description:
                      'Klassisches italienisches Rezept mit frischen Tomaten und Parmesan',
                  ctaText: 'Rezept ansehen',
                  onCtaPressed: () {},
                ),

                const SizedBox(height: AppColors.spacing12),

                // ── 4. KALENDER-SEKTION (Calendar Section) ──────────────
                _CalendarSection(),

                const SizedBox(height: AppColors.spacing8),

                // ── 5. AUFGABEN-SEKTION (Tasks Section) ─────────────────
                _TasksSection(),

                // Bottom padding for bottom nav bar
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Family Status Bubbles ─────────────────────────────────────────────────

/// Horizontal scrollable row of family member status bubbles.
class _FamilyStatusBubbles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Sample family members with different statuses
    final members = [
      _FamilyMember(name: 'Mama', initials: 'M', status: _MemberStatus.online, color: cs.primary),
      _FamilyMember(name: 'Papa', initials: 'P', status: _MemberStatus.busy, color: AppColors.secondary),
      _FamilyMember(name: 'Lina', initials: 'L', status: _MemberStatus.online, color: AppColors.tertiary),
      _FamilyMember(name: 'Max', initials: 'X', status: _MemberStatus.offline, color: cs.primaryContainer),
      _FamilyMember(name: 'Oma', initials: 'O', status: _MemberStatus.offline, color: AppColors.secondaryContainer),
    ];

    return SizedBox(
      height: 88,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (int i = 0; i < members.length; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              _FamilyBubble(member: members[i]),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single family member bubble with avatar, status dot, and name.
class _FamilyBubble extends StatelessWidget {
  final _FamilyMember member;
  const _FamilyBubble({required this.member});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Status border color
    final Color borderColor;
    switch (member.status) {
      case _MemberStatus.online:
        borderColor = cs.primary;
        break;
      case _MemberStatus.busy:
        borderColor = AppColors.secondary;
        break;
      case _MemberStatus.offline:
        borderColor = AppColors.outline;
        break;
    }

    // Status dot color
    final Color dotColor;
    switch (member.status) {
      case _MemberStatus.online:
        dotColor = cs.primary;
        break;
      case _MemberStatus.busy:
        dotColor = AppColors.secondary;
        break;
      case _MemberStatus.offline:
        dotColor = AppColors.outline;
        break;
    }

    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar with outer ring and status dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Outer ring: 64x64
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                ),
                alignment: Alignment.center,
                // Avatar: 56x56
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: member.color.withOpacity(0.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    member.initials,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: member.color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              // Status dot: 16x16, bottom-right
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Name label
          Text(
            member.name.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.05,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Calendar Section ──────────────────────────────────────────────────────

/// Calendar section with header and event cards.
class _CalendarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: AppColors.spacing4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Heutige Termine',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'Alle sehen',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
        ),
        // Event list
        Column(
          children: [
            const SizedBox(height: 16),
            EventCard(
              time: '09:00',
              title: 'Schule — Mathematik',
              location: 'Grundschule am Park',
              barColor: cs.primary,
            ),
            SizedBox(height: 16),
            EventCard(
              time: '14:30',
              title: 'Fußballtraining',
              location: 'Sportplatz Süd',
              barColor: AppColors.secondary,
            ),
            const SizedBox(height: 16),
            EventCard(
              time: '18:00',
              title: 'Familienfilmabend',
              description: 'Kino im Wohnzimmer',
              barColor: AppColors.tertiary,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tasks Section ─────────────────────────────────────────────────────────

/// Tasks section with header and todo items.
class _TasksSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.only(bottom: AppColors.spacing4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aufgaben',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              GestureDetector(
                onTap: () {},
                child: Icon(
                  Icons.more_horiz,
                  color: AppColors.onSurfaceVariant,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
        // Todo list
        const Column(
          children: [
            SizedBox(height: 8),
            TodoItem(
              text: 'Milch und Brot kaufen',
              isChecked: false,
              isPriority: true,
            ),
            SizedBox(height: 8),
            TodoItem(
              text: 'Hausaufgaben mit Lina',
              isChecked: false,
              isPriority: false,
            ),
            SizedBox(height: 8),
            TodoItem(
              text: 'Arzttermin für Max bestätigen',
              isChecked: true,
              isPriority: false,
            ),
            SizedBox(height: 8),
            TodoItem(
              text: 'Wäsche aufhängen',
              isChecked: true,
              isPriority: false,
            ),
          ],
        ),
      ],
    );
  }
}

// ── Data Models (sample) ─────────────────────────────────────────────────

enum _MemberStatus { online, busy, offline }

class _FamilyMember {
  final String name;
  final String initials;
  final _MemberStatus status;
  final Color color;

  const _FamilyMember({
    required this.name,
    required this.initials,
    required this.status,
    required this.color,
  });
}

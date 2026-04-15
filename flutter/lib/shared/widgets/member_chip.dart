import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../features/members/domain/family_member.dart';

/// [toggle]: tap changes selection (todo form). [display]: read-only „zugewiesen“-Darstellung.
enum MemberChipMode { toggle, display }

class MemberChip extends StatelessWidget {
  final FamilyMember member;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;
  final MemberChipMode mode;

  const MemberChip({
    super.key,
    required this.member,
    this.selected = false,
    this.onTap,
    this.compact = false,
    this.mode = MemberChipMode.toggle,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppColors.memberColorFromHex(member.color);
    final theme = Theme.of(context);
    if (compact) {
      final bg = selected ? color : color.withValues(alpha: 0.28);
      final fg = selected ? AppColors.onMemberAccent(color) : color;
      return CircleAvatar(
        radius: 14,
        backgroundColor: bg,
        child: Text(
          member.emoji ?? member.name[0].toUpperCase(),
          style: TextStyle(fontSize: 12, color: fg, fontWeight: selected ? FontWeight.w700 : null),
        ),
      );
    }

    if (mode == MemberChipMode.display && selected) {
      return _StaticAssignedChip(member: member, accent: color, theme: theme);
    }

    return FilterChip(
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      showCheckmark: true,
      checkmarkColor: color,
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: selected ? 0.32 : 0.18),
        child: Text(
          member.emoji ?? member.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: selected ? AppColors.onMemberAccent(color) : color,
            fontWeight: selected ? FontWeight.w700 : null,
          ),
        ),
      ),
      label: Text(
        member.name,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : null,
          color: selected ? theme.colorScheme.onSurface : null,
        ),
      ),
      selectedColor: color.withValues(alpha: 0.4),
      backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      side: WidgetStateBorderSide.resolveWith((states) {
        final isSel = states.contains(WidgetState.selected);
        return BorderSide(
          color: isSel
              ? color
              : theme.colorScheme.outline.withValues(alpha: 0.45),
          width: isSel ? 2 : 1,
        );
      }),
    );
  }
}

class _StaticAssignedChip extends StatelessWidget {
  final FamilyMember member;
  final Color accent;
  final ThemeData theme;

  const _StaticAssignedChip({
    required this.member,
    required this.accent,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 4, right: 12, top: 4, bottom: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.28),
            child: Text(
              member.emoji ?? member.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 13,
                color: AppColors.onMemberAccent(accent),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            member.name,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class MemberChipRow extends StatelessWidget {
  final List<FamilyMember> members;
  final Set<int> selectedIds;
  final ValueChanged<int>? onToggle;

  const MemberChipRow({
    super.key,
    required this.members,
    this.selectedIds = const {},
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: members.map((m) {
        return MemberChip(
          member: m,
          selected: selectedIds.contains(m.id),
          onTap: onToggle != null ? () => onToggle!(m.id) : null,
        );
      }).toList(),
    );
  }
}

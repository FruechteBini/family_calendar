import 'package:flutter/material.dart';
import '../../features/members/domain/family_member.dart';

class MemberChip extends StatelessWidget {
  final FamilyMember member;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  const MemberChip({
    super.key,
    required this.member,
    this.selected = false,
    this.onTap,
    this.compact = false,
  });

  Color _parseColor() {
    if (member.color == null) return Colors.grey;
    try {
      final hex = member.color!.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _parseColor();
    if (compact) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: selected ? color : color.withOpacity(0.3),
        child: Text(
          member.emoji ?? member.name[0].toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : color,
          ),
        ),
      );
    }
    return FilterChip(
      selected: selected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Text(
          member.emoji ?? member.name[0].toUpperCase(),
          style: TextStyle(fontSize: 12, color: color),
        ),
      ),
      label: Text(member.name),
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
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

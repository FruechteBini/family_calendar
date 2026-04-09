/// Creator / comment author as returned by the notes API (FamilyMemberResponse).
class NoteMember {
  final int id;
  final String name;
  final String color;
  final String avatarEmoji;

  const NoteMember({
    required this.id,
    required this.name,
    required this.color,
    required this.avatarEmoji,
  });

  factory NoteMember.fromJson(Map<String, dynamic> json) {
    return NoteMember(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#0052CC',
      avatarEmoji: (json['avatar_emoji'] ?? json['emoji']) as String? ?? '👤',
    );
  }
}

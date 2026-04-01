class FamilyMember {
  final int id;
  final String name;
  final String? emoji;
  final String? color;

  const FamilyMember({
    required this.id,
    required this.name,
    this.emoji,
    this.color,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as int,
      name: json['name'] as String,
      emoji: json['emoji'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (emoji != null) 'emoji': emoji,
      if (color != null) 'color': color,
    };
  }
}

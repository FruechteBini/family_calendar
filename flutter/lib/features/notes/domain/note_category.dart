class NoteCategory {
  final int id;
  final int position;
  final String name;
  final String color;
  final String icon;

  const NoteCategory({
    required this.id,
    required this.position,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    return NoteCategory(
      id: json['id'] as int,
      position: json['position'] as int? ?? 0,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#0052CC',
      icon: json['icon'] as String? ?? '📝',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'icon': icon,
      };
}

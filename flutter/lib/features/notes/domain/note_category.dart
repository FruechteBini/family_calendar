class NoteCategory {
  final int id;
  final int position;
  final String name;
  final String color;
  final String icon;
  final bool isPersonal;

  const NoteCategory({
    required this.id,
    required this.position,
    required this.name,
    required this.color,
    required this.icon,
    required this.isPersonal,
  });

  factory NoteCategory.fromJson(Map<String, dynamic> json) {
    return NoteCategory(
      id: json['id'] as int,
      position: json['position'] as int? ?? 0,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#0052CC',
      icon: json['icon'] as String? ?? '\u{1F4DD}',
      isPersonal: json['is_personal'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color,
        'icon': icon,
        'is_personal': isPersonal,
      };
}

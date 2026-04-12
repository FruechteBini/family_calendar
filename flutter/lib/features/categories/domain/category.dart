class Category {
  final int id;
  final int position;
  final String name;
  final String color;
  final String icon;

  const Category({
    required this.id,
    required this.position,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      position: json['position'] as int? ?? 0,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#0052CC',
      icon: json['icon'] as String? ?? '\u{1F4C1}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
      'position': position,
    };
  }
}

class RecipeCategory {
  final int id;
  final int position;
  final String name;
  final String color;
  final String icon;

  const RecipeCategory({
    required this.id,
    required this.position,
    required this.name,
    this.color = '#0052CC',
    this.icon = '🍽',
  });

  factory RecipeCategory.fromJson(Map<String, dynamic> json) {
    return RecipeCategory(
      id: json['id'] as int,
      position: json['position'] as int? ?? 0,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#0052CC',
      icon: json['icon'] as String? ?? '🍽',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
      if (position != 0) 'position': position,
    };
  }
}

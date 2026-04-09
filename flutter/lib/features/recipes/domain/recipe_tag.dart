class RecipeTag {
  final int id;
  final String name;
  final String color;

  const RecipeTag({
    required this.id,
    required this.name,
    this.color = '#6B7280',
  });

  factory RecipeTag.fromJson(Map<String, dynamic> json) {
    return RecipeTag(
      id: json['id'] as int,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6B7280',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
    };
  }
}

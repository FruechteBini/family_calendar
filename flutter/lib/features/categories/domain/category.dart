class Category {
  final int id;
  final int position;
  final String name;
  final String? color;

  const Category({
    required this.id,
    required this.position,
    required this.name,
    this.color,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      position: json['position'] as int? ?? 0,
      name: json['name'] as String,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (color != null) 'color': color,
      'position': position,
    };
  }
}

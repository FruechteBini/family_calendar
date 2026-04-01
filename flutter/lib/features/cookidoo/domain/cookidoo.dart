class CookidooStatus {
  final bool available;
  final String? message;

  const CookidooStatus({this.available = false, this.message});

  factory CookidooStatus.fromJson(Map<String, dynamic> json) {
    return CookidooStatus(
      available: json['available'] as bool? ?? false,
      message: json['message'] as String?,
    );
  }
}

class CookidooCollection {
  final String id;
  final String name;
  final int recipeCount;
  final String? imageUrl;

  const CookidooCollection({
    required this.id,
    required this.name,
    this.recipeCount = 0,
    this.imageUrl,
  });

  factory CookidooCollection.fromJson(Map<String, dynamic> json) {
    return CookidooCollection(
      id: json['id'] as String,
      name: json['name'] as String,
      recipeCount: json['recipe_count'] as int? ?? 0,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class CookidooRecipe {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> ingredients;
  final int? servings;
  final String? difficulty;
  final String? prepTime;

  const CookidooRecipe({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.ingredients = const [],
    this.servings,
    this.difficulty,
    this.prepTime,
  });

  factory CookidooRecipe.fromJson(Map<String, dynamic> json) {
    return CookidooRecipe(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      servings: json['servings'] as int?,
      difficulty: json['difficulty'] as String?,
      prepTime: json['prep_time'] as String?,
    );
  }
}

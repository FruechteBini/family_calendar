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

class CookidooChapter {
  final String name;
  final List<CookidooRecipe> recipes;

  const CookidooChapter({required this.name, this.recipes = const []});

  factory CookidooChapter.fromJson(Map<String, dynamic> json) {
    return CookidooChapter(
      name: (json['name'] as String?) ?? '',
      recipes: ((json['recipes'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CookidooRecipe.fromJson)
          .toList(),
    );
  }
}

class CookidooCollection {
  final String id;
  final String name;
  final String? description;
  final List<CookidooChapter> chapters;

  const CookidooCollection({
    required this.id,
    required this.name,
    this.description,
    this.chapters = const [],
  });

  int get recipeCount =>
      chapters.fold<int>(0, (sum, ch) => sum + ch.recipes.length);

  factory CookidooCollection.fromJson(Map<String, dynamic> json) {
    return CookidooCollection(
      id: (json['id'] as Object?)?.toString() ?? '',
      name: json['name'] as String,
      description: json['description'] as String?,
      chapters: ((json['chapters'] as List<dynamic>?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(CookidooChapter.fromJson)
          .toList(),
    );
  }
}

class CookidooRecipe {
  final String id;
  final String name;
  final String? description;
  final String? instructions;
  final String? imageUrl;
  final List<String> ingredients;
  final int? servings;
  final String? difficulty;
  final String? prepTime;
  final String? totalTime;
  final String? url;

  const CookidooRecipe({
    required this.id,
    required this.name,
    this.description,
    this.instructions,
    this.imageUrl,
    this.ingredients = const [],
    this.servings,
    this.difficulty,
    this.prepTime,
    this.totalTime,
    this.url,
  });

  factory CookidooRecipe.fromJson(Map<String, dynamic> json) {
    // Backend shapes:
    // - collections/shopping-list: { cookidoo_id, name, thumbnail, total_time, url, ... }
    // - detail: { cookidoo_id, name, image, active_time/total_time, serving_size, difficulty, instructions, ... }
    final cookidooId = (json['cookidoo_id'] as String?) ?? (json['id'] as String?);
    if (cookidooId == null || cookidooId.isEmpty) {
      throw ArgumentError('Cookidoo recipe is missing cookidoo_id');
    }

    final rawIngredients = (json['ingredients'] as List<dynamic>?) ?? const [];
    final ingredients = rawIngredients.map((e) {
      if (e is Map<String, dynamic>) {
        return (e['name'] as String?) ?? (e['description'] as String?) ?? e.toString();
      }
      return e.toString();
    }).toList();

    String? asString(dynamic v) {
      if (v == null) return null;
      if (v is String) return v;
      if (v is num) return v.toString();
      return v.toString();
    }

    final desc = (json['description'] as String?)?.trim();
    final inst = (json['instructions'] as String?)?.trim();
    return CookidooRecipe(
      id: cookidooId,
      name: (json['name'] as String?) ?? '',
      description: (desc != null && desc.isNotEmpty) ? desc : null,
      instructions: (inst != null && inst.isNotEmpty) ? inst : null,
      imageUrl: (json['image_url'] as String?) ??
          (json['thumbnail'] as String?) ??
          (json['image'] as String?),
      ingredients: ingredients,
      servings: (json['servings'] as int?) ?? (json['serving_size'] as int?),
      difficulty: json['difficulty'] as String?,
      prepTime: asString(json['prep_time']) ?? asString(json['active_time']),
      totalTime: asString(json['total_time']),
      url: json['url'] as String?,
    );
  }
}

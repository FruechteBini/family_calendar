import 'recipe_tag.dart';

class Recipe {
  final int id;
  final String name;
  final String? description;
  final String difficulty; // einfach, mittel, schwer
  final int? prepTime;
  final String? imageUrl;
  final String? sourceUrl;
  final bool isCookidoo;
  final String? cookidooId;
  final List<Ingredient> ingredients;
  final DateTime? lastCooked;
  final int cookCount;
  final int? categoryId;
  final String? categoryName;
  final String? categoryColor;
  final List<RecipeTag> tags;

  const Recipe({
    required this.id,
    required this.name,
    this.description,
    this.difficulty = 'mittel',
    this.prepTime,
    this.imageUrl,
    this.sourceUrl,
    this.isCookidoo = false,
    this.cookidooId,
    this.ingredients = const [],
    this.lastCooked,
    this.cookCount = 0,
    this.categoryId,
    this.categoryName,
    this.categoryColor,
    this.tags = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    // Backend uses `title`, `notes` and `prep_time_*_minutes`.
    final active = json['prep_time_active_minutes'] as int?;
    final passive = json['prep_time_passive_minutes'] as int?;
    final prepTotal = (active ?? 0) + (passive ?? 0);
    final source = json['source'] as String?;
    final cat = json['category'] as Map<String, dynamic>?;
    final tagsJson = json['tags'] as List<dynamic>?;
    return Recipe(
      id: json['id'] as int,
      name: (json['title'] as String?) ?? (json['name'] as String?) ?? '',
      description: (json['notes'] as String?) ?? (json['description'] as String?),
      difficulty: const {'easy': 'einfach', 'medium': 'mittel', 'hard': 'schwer'}[json['difficulty']] ?? json['difficulty'] as String? ?? 'mittel',
      prepTime: prepTotal > 0 ? prepTotal : (json['prep_time'] as int?),
      imageUrl: json['image_url'] as String?,
      sourceUrl: json['source_url'] as String?,
      isCookidoo: source == 'cookidoo' || (json['is_cookidoo'] as bool? ?? false),
      cookidooId: json['cookidoo_id'] as String?,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastCooked: (json['last_cooked_at'] ?? json['last_cooked']) != null
          ? DateTime.parse((json['last_cooked_at'] ?? json['last_cooked']) as String)
          : null,
      cookCount: json['cook_count'] as int? ?? 0,
      categoryId: json['recipe_category_id'] as int? ?? cat?['id'] as int?,
      categoryName: cat?['name'] as String?,
      categoryColor: cat?['color'] as String?,
      tags: tagsJson
              ?.whereType<Map<String, dynamic>>()
              .map(RecipeTag.fromJson)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    const diffMap = {'einfach': 'easy', 'mittel': 'medium', 'schwer': 'hard'};
    return {
      'title': name,
      if (description != null) 'notes': description,
      'difficulty': diffMap[difficulty] ?? difficulty,
      if (prepTime != null) 'prep_time_active_minutes': prepTime,
      if (imageUrl != null) 'image_url': imageUrl,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'recipe_category_id': categoryId,
      'tag_ids': tags.map((t) => t.id).toList(),
    };
  }
}

class Ingredient {
  final int? id;
  final String name;
  final double? amount;
  final String? unit;

  const Ingredient({this.id, required this.name, this.amount, this.unit});

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as int?,
      name: json['name'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (amount != null) 'amount': amount,
      if (unit != null) 'unit': unit,
    };
  }
}

class CookingHistoryEntry {
  final int id;
  final int recipeId;
  final String recipeName;
  final DateTime cookedAt;
  final int? rating;

  const CookingHistoryEntry({
    required this.id,
    required this.recipeId,
    required this.recipeName,
    required this.cookedAt,
    this.rating,
  });

  factory CookingHistoryEntry.fromJson(Map<String, dynamic> json) {
    return CookingHistoryEntry(
      id: json['id'] as int,
      recipeId: json['recipe_id'] as int,
      recipeName: json['recipe_name'] as String,
      cookedAt: DateTime.parse(json['cooked_at'] as String),
      rating: json['rating'] as int?,
    );
  }
}

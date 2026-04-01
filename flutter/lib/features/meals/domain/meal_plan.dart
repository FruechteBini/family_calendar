class MealPlan {
  final Map<String, DayPlan> days;

  const MealPlan({this.days = const {}});

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final days = <String, DayPlan>{};
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        days[key] = DayPlan.fromJson(value);
      }
    });
    return MealPlan(days: days);
  }
}

class DayPlan {
  final MealSlot? lunch;
  final MealSlot? dinner;

  const DayPlan({this.lunch, this.dinner});

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      lunch: json['lunch'] != null
          ? MealSlot.fromJson(json['lunch'] as Map<String, dynamic>)
          : null,
      dinner: json['dinner'] != null
          ? MealSlot.fromJson(json['dinner'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MealSlot {
  final int? recipeId;
  final String? recipeName;
  final String? imageUrl;
  final bool cooked;
  final int? rating;
  final String? difficulty;

  const MealSlot({
    this.recipeId,
    this.recipeName,
    this.imageUrl,
    this.cooked = false,
    this.rating,
    this.difficulty,
  });

  factory MealSlot.fromJson(Map<String, dynamic> json) {
    return MealSlot(
      recipeId: json['recipe_id'] as int?,
      recipeName: json['recipe_name'] as String?,
      imageUrl: json['image_url'] as String?,
      cooked: json['cooked'] as bool? ?? false,
      rating: json['rating'] as int?,
      difficulty: json['difficulty'] as String?,
    );
  }
}

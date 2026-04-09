class MealPlan {
  final Map<String, DayPlan> days;

  const MealPlan({this.days = const {}});

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final days = <String, DayPlan>{};
    final rawDays = json['days'];
    if (rawDays is List) {
      // Backend format: {"week_start": "...", "days": [{"date": "2026-04-06", ...}, ...]}
      for (final item in rawDays) {
        if (item is Map<String, dynamic>) {
          final dateStr = item['date'] as String?;
          if (dateStr != null) {
            days[dateStr] = DayPlan.fromJson(item);
          }
        }
      }
    } else {
      // Fallback: direct map format {"2026-04-06": {"lunch": ..., "dinner": ...}}
      json.forEach((key, value) {
        if (key != 'week_start' && value is Map<String, dynamic>) {
          days[key] = DayPlan.fromJson(value);
        }
      });
    }
    return MealPlan(days: days);
  }
}

class DayPlan {
  final String? date;
  final String? weekday;
  final MealSlot? lunch;
  final MealSlot? dinner;

  const DayPlan({this.date, this.weekday, this.lunch, this.dinner});

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      date: json['date'] as String?,
      weekday: json['weekday'] as String?,
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
    // Backend MealSlotResponse format: recipe is a nested object
    final recipe = json['recipe'];
    return MealSlot(
      recipeId: json['recipe_id'] as int?,
      recipeName: recipe is Map<String, dynamic>
          ? (recipe['title'] as String?)
          : (json['recipe_name'] as String?),
      imageUrl: recipe is Map<String, dynamic>
          ? (recipe['image_url'] as String?)
          : (json['image_url'] as String?),
      cooked: json['cooked'] as bool? ?? false,
      rating: json['rating'] as int?,
      difficulty: recipe is Map<String, dynamic>
          ? (recipe['difficulty'] as String?)
          : null,
    );
  }
}

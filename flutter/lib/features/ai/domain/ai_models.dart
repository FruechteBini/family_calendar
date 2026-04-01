class AiAvailableRecipes {
  final List<AiRecipeOption> recipes;
  final List<AiSlotOption> availableSlots;

  const AiAvailableRecipes({
    this.recipes = const [],
    this.availableSlots = const [],
  });

  factory AiAvailableRecipes.fromJson(Map<String, dynamic> json) {
    return AiAvailableRecipes(
      recipes: (json['recipes'] as List<dynamic>?)
              ?.map((e) => AiRecipeOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      availableSlots: (json['available_slots'] as List<dynamic>?)
              ?.map((e) => AiSlotOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class AiRecipeOption {
  final int id;
  final String name;
  final DateTime? lastCooked;
  final int cookCount;
  final bool isCookidoo;

  const AiRecipeOption({
    required this.id,
    required this.name,
    this.lastCooked,
    this.cookCount = 0,
    this.isCookidoo = false,
  });

  factory AiRecipeOption.fromJson(Map<String, dynamic> json) {
    return AiRecipeOption(
      id: json['id'] as int,
      name: json['name'] as String,
      lastCooked: json['last_cooked'] != null
          ? DateTime.parse(json['last_cooked'] as String)
          : null,
      cookCount: json['cook_count'] as int? ?? 0,
      isCookidoo: json['is_cookidoo'] as bool? ?? false,
    );
  }
}

class AiSlotOption {
  final String date;
  final String slot;
  final bool occupied;

  const AiSlotOption({
    required this.date,
    required this.slot,
    this.occupied = false,
  });

  factory AiSlotOption.fromJson(Map<String, dynamic> json) {
    return AiSlotOption(
      date: json['date'] as String,
      slot: json['slot'] as String,
      occupied: json['occupied'] as bool? ?? false,
    );
  }
}

class AiMealPlanPreview {
  final List<AiMealSuggestion> suggestions;
  final String? reasoning;

  const AiMealPlanPreview({this.suggestions = const [], this.reasoning});

  factory AiMealPlanPreview.fromJson(Map<String, dynamic> json) {
    return AiMealPlanPreview(
      suggestions: (json['suggestions'] as List<dynamic>?)
              ?.map(
                  (e) => AiMealSuggestion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reasoning: json['reasoning'] as String?,
    );
  }
}

class AiMealSuggestion {
  final String date;
  final String slot;
  final int recipeId;
  final String recipeName;
  final String? reasoning;
  final bool isCookidoo;
  final String? cookidooId;

  const AiMealSuggestion({
    required this.date,
    required this.slot,
    required this.recipeId,
    required this.recipeName,
    this.reasoning,
    this.isCookidoo = false,
    this.cookidooId,
  });

  factory AiMealSuggestion.fromJson(Map<String, dynamic> json) {
    return AiMealSuggestion(
      date: json['date'] as String,
      slot: json['slot'] as String,
      recipeId: json['recipe_id'] as int,
      recipeName: json['recipe_name'] as String,
      reasoning: json['reasoning'] as String?,
      isCookidoo: json['is_cookidoo'] as bool? ?? false,
      cookidooId: json['cookidoo_id'] as String?,
    );
  }
}

class AiMealPlanConfirmResult {
  final List<int> mealIds;
  final int? shoppingListId;

  const AiMealPlanConfirmResult({this.mealIds = const [], this.shoppingListId});

  factory AiMealPlanConfirmResult.fromJson(Map<String, dynamic> json) {
    return AiMealPlanConfirmResult(
      mealIds: (json['meal_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      shoppingListId: json['shopping_list_id'] as int?,
    );
  }
}

class VoiceCommandResult {
  final bool success;
  final List<VoiceAction> actions;
  final String? summary;

  const VoiceCommandResult({
    this.success = false,
    this.actions = const [],
    this.summary,
  });

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) {
    return VoiceCommandResult(
      success: json['success'] as bool? ?? false,
      actions: (json['actions'] as List<dynamic>?)
              ?.map((e) => VoiceAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String?,
    );
  }
}

class VoiceAction {
  final String type;
  final bool success;
  final String? message;
  final Map<String, dynamic>? data;

  const VoiceAction({
    required this.type,
    this.success = false,
    this.message,
    this.data,
  });

  factory VoiceAction.fromJson(Map<String, dynamic> json) {
    return VoiceAction(
      type: json['type'] as String,
      success: json['success'] as bool? ?? false,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

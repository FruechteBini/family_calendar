class AiAvailableRecipes {
  final List<AiRecipeOption> recipes;
  final List<AiSlotOption> availableSlots;
  final int localCount;
  final int cookidooCount;
  final bool cookidooAvailable;

  const AiAvailableRecipes({
    this.recipes = const [],
    this.availableSlots = const [],
    this.localCount = 0,
    this.cookidooCount = 0,
    this.cookidooAvailable = false,
  });

  factory AiAvailableRecipes.fromJson(Map<String, dynamic> json) {
    // Backend currently returns:
    // { local_count, local_recipes, cookidoo_available, cookidoo_count, filled_slots, empty_slots }
    // Older/alternate shapes might return:
    // { recipes, available_slots }
    final localCount = json['local_count'] as int? ?? 0;
    final cookidooCount = json['cookidoo_count'] as int? ?? 0;
    final cookidooAvailable = json['cookidoo_available'] as bool? ?? false;

    final localRecipesRaw = (json['local_recipes'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    final recipesRaw = (json['recipes'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList();

    final emptySlotsRaw = (json['empty_slots'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    final filledSlotsRaw = (json['filled_slots'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList();
    final availableSlotsRaw = (json['available_slots'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .toList();

    final slots = <AiSlotOption>[
      ...?emptySlotsRaw?.map((e) => AiSlotOption.fromJson({
            ...e,
            'occupied': false,
          })),
      ...?filledSlotsRaw?.map((e) => AiSlotOption.fromJson({
            ...e,
            'occupied': true,
          })),
      ...?availableSlotsRaw?.map(AiSlotOption.fromJson),
    ];

    return AiAvailableRecipes(
      localCount: localCount,
      cookidooCount: cookidooCount,
      cookidooAvailable: cookidooAvailable,
      recipes: (localRecipesRaw ?? recipesRaw ?? const [])
          .map(AiRecipeOption.fromJson)
          .toList(),
      availableSlots: slots,
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
      name: (json['name'] ?? json['title']) as String? ?? '',
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
  final String? day;
  final String? label;
  final String? recipeTitle;

  const AiSlotOption({
    required this.date,
    required this.slot,
    this.occupied = false,
    this.day,
    this.label,
    this.recipeTitle,
  });

  factory AiSlotOption.fromJson(Map<String, dynamic> json) {
    return AiSlotOption(
      date: json['date'] as String,
      slot: json['slot'] as String,
      occupied: json['occupied'] as bool? ?? false,
      day: json['day'] as String?,
      label: json['label'] as String?,
      recipeTitle: json['recipe_title'] as String?,
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
  final int? recipeId;
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
      recipeId: json['recipe_id'] as int?,
      recipeName: (json['recipe_title'] ?? json['recipe_name']) as String? ?? '',
      reasoning: json['reasoning'] as String?,
      isCookidoo: json['is_cookidoo'] as bool? ?? false,
      cookidooId: json['cookidoo_id'] as String?,
    );
  }
}

class AiMealPlanConfirmResult {
  final List<int> mealIds;
  final int? shoppingListId;
  final Map<String, dynamic>? knuspr;

  const AiMealPlanConfirmResult({
    this.mealIds = const [],
    this.shoppingListId,
    this.knuspr,
  });

  factory AiMealPlanConfirmResult.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? k;
    final raw = json['knuspr'];
    if (raw is Map<String, dynamic>) {
      k = raw;
    }
    return AiMealPlanConfirmResult(
      mealIds: (json['meal_ids'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      shoppingListId: json['shopping_list_id'] as int?,
      knuspr: k,
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
    final actions = (json['actions'] as List<dynamic>?)
            ?.map((e) => VoiceAction.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const <VoiceAction>[];

    // Backend returns {summary, actions} and encodes errors inside action.result.error.
    // Some clients may send explicit {success}, so prefer it when present.
    final explicitSuccess = json['success'];
    final computedSuccess =
        actions.isNotEmpty && actions.any((a) => a.success == true);

    return VoiceCommandResult(
      success: explicitSuccess is bool ? explicitSuccess : computedSuccess,
      actions: actions,
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
    final result = json['result'];
    final resultMap = result is Map<String, dynamic> ? result : null;
    final hasError = resultMap != null &&
        resultMap.containsKey('error') &&
        resultMap['error'] != null &&
        (resultMap['error'] as Object).toString().trim().isNotEmpty;

    final explicitSuccess = json['success'];
    final computedSuccess = resultMap != null ? !hasError : false;

    return VoiceAction(
      type: json['type'] as String,
      success: explicitSuccess is bool ? explicitSuccess : computedSuccess,
      message: json['message'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>() ??
          resultMap?.cast<String, dynamic>(),
    );
  }
}

// ── Recipe AI categorization ─────────────────────────────────────────────

class RecipeNewCategorySpec {
  final String name;
  final String color;

  const RecipeNewCategorySpec({required this.name, this.color = '#0052CC'});

  factory RecipeNewCategorySpec.fromJson(Map<String, dynamic> json) {
    return RecipeNewCategorySpec(
      name: json['name'] as String,
      color: json['color'] as String? ?? '#0052CC',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'color': color};
}

class RecipeNewTagSpec {
  final String name;
  final String color;

  const RecipeNewTagSpec({required this.name, this.color = '#6B7280'});

  factory RecipeNewTagSpec.fromJson(Map<String, dynamic> json) {
    return RecipeNewTagSpec(
      name: json['name'] as String,
      color: json['color'] as String? ?? '#6B7280',
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'color': color};
}

class RecipeCategorizationAssignment {
  final int recipeId;
  final String categoryName;
  final int? suggestedCategoryId;
  final List<String> tagNames;

  const RecipeCategorizationAssignment({
    required this.recipeId,
    required this.categoryName,
    this.suggestedCategoryId,
    this.tagNames = const [],
  });

  factory RecipeCategorizationAssignment.fromJson(Map<String, dynamic> json) {
    final tags = json['tag_names'] as List<dynamic>?;
    return RecipeCategorizationAssignment(
      recipeId: json['recipe_id'] as int,
      categoryName: json['category_name'] as String? ?? '',
      suggestedCategoryId: json['suggested_category_id'] as int?,
      tagNames: tags?.whereType<String>().toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
        'recipe_id': recipeId,
        'category_name': categoryName,
        'suggested_category_id': suggestedCategoryId,
        'tag_names': tagNames,
      };
}

class RecipeCategorizationPreview {
  final List<RecipeNewCategorySpec> newCategories;
  final List<RecipeNewTagSpec> newTags;
  final List<RecipeCategorizationAssignment> assignments;
  final String summary;

  const RecipeCategorizationPreview({
    this.newCategories = const [],
    this.newTags = const [],
    this.assignments = const [],
    this.summary = '',
  });

  factory RecipeCategorizationPreview.fromJson(Map<String, dynamic> json) {
    return RecipeCategorizationPreview(
      newCategories: (json['new_categories'] as List<dynamic>?)
              ?.map((e) =>
                  RecipeNewCategorySpec.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      newTags: (json['new_tags'] as List<dynamic>?)
              ?.map(
                  (e) => RecipeNewTagSpec.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => RecipeCategorizationAssignment.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toApplyBody() => {
        'new_categories': newCategories.map((e) => e.toJson()).toList(),
        'new_tags': newTags.map((e) => e.toJson()).toList(),
        'assignments': assignments.map((e) => e.toJson()).toList(),
      };
}

class ApplyRecipeCategorizationResult {
  final int updated;
  final int categoriesCreated;
  final int tagsCreated;

  const ApplyRecipeCategorizationResult({
    this.updated = 0,
    this.categoriesCreated = 0,
    this.tagsCreated = 0,
  });

  factory ApplyRecipeCategorizationResult.fromJson(Map<String, dynamic> json) {
    return ApplyRecipeCategorizationResult(
      updated: json['updated'] as int? ?? 0,
      categoriesCreated: json['categories_created'] as int? ?? 0,
      tagsCreated: json['tags_created'] as int? ?? 0,
    );
  }
}

// ── Pantry AI categorization ───────────────────────────────────────────────

class PantryCategoryAssignment {
  final int pantryItemId;
  final String itemName;
  final String category;

  const PantryCategoryAssignment({
    required this.pantryItemId,
    this.itemName = '',
    required this.category,
  });

  factory PantryCategoryAssignment.fromJson(Map<String, dynamic> json) {
    return PantryCategoryAssignment(
      pantryItemId: json['pantry_item_id'] as int,
      itemName: json['item_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'pantry_item_id': pantryItemId,
        if (itemName.isNotEmpty) 'item_name': itemName,
        'category': category,
      };
}

class PantryCategorizationPreview {
  final List<PantryCategoryAssignment> assignments;
  final String summary;

  const PantryCategorizationPreview({
    this.assignments = const [],
    this.summary = '',
  });

  factory PantryCategorizationPreview.fromJson(Map<String, dynamic> json) {
    return PantryCategorizationPreview(
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) =>
                  PantryCategoryAssignment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      summary: json['summary'] as String? ?? '',
    );
  }

  Map<String, dynamic> toApplyBody() => {
        'assignments': assignments.map((e) => e.toJson()).toList(),
      };
}

class ApplyPantryCategorizationResult {
  final int updated;

  const ApplyPantryCategorizationResult({this.updated = 0});

  factory ApplyPantryCategorizationResult.fromJson(Map<String, dynamic> json) {
    return ApplyPantryCategorizationResult(
      updated: json['updated'] as int? ?? 0,
    );
  }
}

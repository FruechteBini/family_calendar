import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/ai_models.dart';

class AiRepository {
  final Dio _dio;

  AiRepository(this._dio);

  Future<AiAvailableRecipes> getAvailableRecipes({
    required String weekStart, // YYYY-MM-DD (Monday)
    bool includeCookidoo = false,
  }) async {
    try {
      final response = await _dio.get(
        Endpoints.aiAvailableRecipes,
        queryParameters: {
          'week_start': weekStart,
          'include_cookidoo': includeCookidoo,
        },
      );
      return AiAvailableRecipes.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AiMealPlanPreview> generateMealPlan({
    required String weekStart, // YYYY-MM-DD (Monday)
    required List<Map<String, String>> selectedSlots,
    bool includeCookidoo = false,
    int servings = 2,
    String? preferences,
  }) async {
    try {
      final response = await _dio.post(
        Endpoints.aiGenerateMealPlan,
        data: {
          'week_start': weekStart,
          'selected_slots': selectedSlots,
          'include_cookidoo': includeCookidoo,
          'servings': servings,
          if (preferences != null) 'preferences': preferences,
        },
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      return AiMealPlanPreview.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<AiMealPlanConfirmResult> confirmMealPlan(
    String weekStart, // YYYY-MM-DD (Monday)
    List<AiMealSuggestion> suggestions, {
    bool sendToKnuspr = false,
  }) async {
    try {
      final response = await _dio.post(
        Endpoints.aiConfirmMealPlan,
        data: {
          'week_start': weekStart,
          'send_to_knuspr': sendToKnuspr,
          'items': suggestions
              .map((s) => {
                    'date': s.date,
                    'slot': s.slot,
                    'recipe_id': s.recipeId,
                    if (s.cookidooId != null) 'cookidoo_id': s.cookidooId,
                    'recipe_title': s.recipeName,
                    'servings_planned': 2,
                    'source': s.isCookidoo ? 'cookidoo' : 'local',
                  })
              .toList(),
        },
      );
      return AiMealPlanConfirmResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> undoMealPlan(List<int> mealIds) async {
    try {
      await _dio.post(
        Endpoints.aiUndoMealPlan,
        data: {'meal_ids': mealIds},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RecipeCategorizationPreview> categorizeRecipes() async {
    try {
      final response = await _dio.post(
        Endpoints.aiCategorizeRecipes,
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      return RecipeCategorizationPreview.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApplyRecipeCategorizationResult> applyRecipeCategorization(
    RecipeCategorizationPreview preview,
  ) async {
    try {
      final response = await _dio.post(
        Endpoints.aiApplyRecipeCategorization,
        data: preview.toApplyBody(),
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      return ApplyRecipeCategorizationResult.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PantryCategorizationPreview> categorizePantry() async {
    try {
      final response = await _dio.post(
        Endpoints.aiCategorizePantry,
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      return PantryCategorizationPreview.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ApplyPantryCategorizationResult> applyPantryCategorization(
    PantryCategorizationPreview preview,
  ) async {
    try {
      final response = await _dio.post(
        Endpoints.aiApplyPantryCategorization,
        data: preview.toApplyBody(),
        options: Options(receiveTimeout: const Duration(seconds: 120)),
      );
      return ApplyPantryCategorizationResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<VoiceCommandResult> voiceCommand({
    required String text,
    List<Map<String, dynamic>>? context,
  }) async {
    try {
      final response = await _dio.post(
        Endpoints.aiVoiceCommand,
        data: {
          'text': text,
          if (context != null) 'context': context,
        },
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );
      return VoiceCommandResult.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  return AiRepository(ref.watch(dioProvider));
});

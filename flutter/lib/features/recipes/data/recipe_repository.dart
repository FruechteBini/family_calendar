import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/recipe.dart';

class RecipeRepository {
  final Dio _dio;

  RecipeRepository(this._dio);

  Future<Recipe> getRecipe(int id) async {
    try {
      final response = await _dio.get(Endpoints.recipe(id));
      return Recipe.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Recipe>> getRecipes({
    int? recipeCategoryId,
    int? tagId,
  }) async {
    try {
      final qp = <String, dynamic>{};
      if (recipeCategoryId != null) {
        qp['recipe_category_id'] = recipeCategoryId;
      }
      if (tagId != null) {
        qp['tag_id'] = tagId;
      }
      final response = await _dio.get(
        Endpoints.recipes,
        queryParameters: qp.isEmpty ? null : qp,
      );
      return (response.data as List)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Recipe> createRecipe(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.recipes, data: data);
      return Recipe.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Recipe> updateRecipe(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.recipe(id), data: data);
      return Recipe.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteRecipe(int id) async {
    try {
      await _dio.delete(Endpoints.recipe(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Recipe>> getSuggestions() async {
    try {
      final response = await _dio.get(Endpoints.recipeSuggestions);
      return (response.data as List)
          .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Recipe> parseUrl(String url) async {
    try {
      final response = await _dio.post(
        Endpoints.recipeParseUrl,
        data: {'url': url},
      );
      final d = response.data as Map<String, dynamic>;
      // UrlImportPreview uses 'title', Recipe uses 'name'; no id yet
      final activeMin = d['prep_time_active_minutes'] as int? ?? 0;
      final passiveMin = d['prep_time_passive_minutes'] as int? ?? 0;
      return Recipe(
        id: 0,
        name: d['title'] as String? ?? '',
        instructions: d['instructions'] as String?,
        difficulty: const {'easy': 'einfach', 'medium': 'mittel', 'hard': 'schwer'}[d['difficulty']] ?? 'mittel',
        prepTime: (activeMin + passiveMin) > 0 ? activeMin + passiveMin : null,
        imageUrl: d['image_url'] as String?,
        sourceUrl: d['source_url'] as String?,
        ingredients: (d['ingredients'] as List<dynamic>?)
                ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        tags: const [],
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CookingHistoryEntry>> getHistory({int? recipeId}) async {
    try {
      final params = <String, dynamic>{};
      if (recipeId != null) params['recipe_id'] = recipeId;
      final response = await _dio.get(
        Endpoints.mealsHistory,
        queryParameters: params,
      );
      return (response.data as List)
          .map((e) => CookingHistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final recipeRepositoryProvider = Provider<RecipeRepository>((ref) {
  return RecipeRepository(ref.watch(dioProvider));
});

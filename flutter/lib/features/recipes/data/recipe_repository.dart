import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/recipe.dart';

class RecipeRepository {
  final Dio _dio;

  RecipeRepository(this._dio);

  Future<List<Recipe>> getRecipes() async {
    try {
      final response = await _dio.get(Endpoints.recipes);
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
      return Recipe.fromJson(response.data);
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

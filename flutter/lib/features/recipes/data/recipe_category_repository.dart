import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/recipe_category.dart';

class RecipeCategoryRepository {
  final Dio _dio;

  RecipeCategoryRepository(this._dio);

  Future<List<RecipeCategory>> getCategories() async {
    try {
      final response = await _dio.get(Endpoints.recipeCategories);
      return (response.data as List)
          .map((e) => RecipeCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RecipeCategory> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.recipeCategories, data: data);
      return RecipeCategory.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RecipeCategory> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.recipeCategory(id), data: data);
      return RecipeCategory.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete(Endpoints.recipeCategory(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> reorderCategories(List<int> ids) async {
    try {
      await _dio.put(Endpoints.recipeCategoriesReorder, data: {'ids': ids});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final recipeCategoryRepositoryProvider =
    Provider<RecipeCategoryRepository>((ref) {
  return RecipeCategoryRepository(ref.watch(dioProvider));
});

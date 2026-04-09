import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/recipe_tag.dart';

class RecipeTagRepository {
  final Dio _dio;

  RecipeTagRepository(this._dio);

  Future<List<RecipeTag>> getTags() async {
    try {
      final response = await _dio.get(Endpoints.recipeTags);
      return (response.data as List)
          .map((e) => RecipeTag.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RecipeTag> createTag(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.recipeTags, data: data);
      return RecipeTag.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<RecipeTag> updateTag(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.recipeTag(id), data: data);
      return RecipeTag.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteTag(int id) async {
    try {
      await _dio.delete(Endpoints.recipeTag(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final recipeTagRepositoryProvider = Provider<RecipeTagRepository>((ref) {
  return RecipeTagRepository(ref.watch(dioProvider));
});

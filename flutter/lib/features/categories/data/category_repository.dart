import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/category.dart';

class CategoryRepository {
  final Dio _dio;

  CategoryRepository(this._dio);

  /// [scope] `all` = eigene persönliche + Familien-Kategorien (z. B. Todos),
  /// `personal` / `family` für die Kategorien-Verwaltung.
  Future<List<Category>> getCategories({String scope = 'all'}) async {
    try {
      final response = await _dio.get(
        Endpoints.categories,
        queryParameters: {'scope': scope},
      );
      return (response.data as List)
          .map((e) => Category.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Category> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.categories, data: data);
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Category> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.category(id), data: data);
      return Category.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete(Endpoints.category(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> reorderCategories(
    List<int> ids, {
    required bool isPersonal,
  }) async {
    try {
      await _dio.put(
        Endpoints.categoriesReorder,
        data: {'ids': ids},
        queryParameters: {
          'scope': isPersonal ? 'personal' : 'family',
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(ref.watch(dioProvider));
});

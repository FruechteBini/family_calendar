import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/note_category.dart';

class NoteCategoryRepository {
  final Dio _dio;

  NoteCategoryRepository(this._dio);

  Future<List<NoteCategory>> getCategories() async {
    try {
      final response = await _dio.get(Endpoints.noteCategories);
      return (response.data as List)
          .map((e) => NoteCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NoteCategory> createCategory(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.noteCategories, data: data);
      return NoteCategory.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<NoteCategory> updateCategory(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.noteCategory(id), data: data);
      return NoteCategory.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteCategory(int id) async {
    try {
      await _dio.delete(Endpoints.noteCategory(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> reorderCategories(List<int> ids) async {
    try {
      await _dio.put(Endpoints.noteCategoriesReorder, data: {'ids': ids});
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final noteCategoryRepositoryProvider =
    Provider<NoteCategoryRepository>((ref) {
  return NoteCategoryRepository(ref.watch(dioProvider));
});

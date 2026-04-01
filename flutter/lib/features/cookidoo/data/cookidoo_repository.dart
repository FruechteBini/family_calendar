import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/cookidoo.dart';

class CookidooRepository {
  final Dio _dio;

  CookidooRepository(this._dio);

  Future<CookidooStatus> getStatus() async {
    try {
      final response = await _dio.get(Endpoints.cookidooStatus);
      return CookidooStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CookidooCollection>> getCollections() async {
    try {
      final response = await _dio.get(Endpoints.cookidooCollections);
      return (response.data as List)
          .map((e) => CookidooCollection.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<CookidooRecipe> getRecipe(String id) async {
    try {
      final response = await _dio.get(Endpoints.cookidooRecipe(id));
      return CookidooRecipe.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> importRecipe(String cookidooId) async {
    try {
      await _dio.post(Endpoints.cookidooRecipeImport(cookidooId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> getCalendar() async {
    try {
      final response = await _dio.get(Endpoints.cookidooCalendar);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final cookidooRepositoryProvider = Provider<CookidooRepository>((ref) {
  return CookidooRepository(ref.watch(dioProvider));
});

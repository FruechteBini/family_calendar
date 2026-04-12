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
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(CookidooCollection.fromJson)
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<CookidooRecipe>> getShoppingList() async {
    try {
      final response = await _dio.get(Endpoints.cookidooShoppingList);
      final data = response.data;
      if (data is! List) return const [];
      return data
          .whereType<Map<String, dynamic>>()
          .map(CookidooRecipe.fromJson)
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

  /// Rezepte in Cookidoo „Mein Tag“ legen ([day] = lokales Kalenderdatum, Standard: heute).
  Future<void> planRecipesOnCookidooDay(
    List<String> cookidooIds, {
    DateTime? day,
  }) async {
    try {
      final body = <String, dynamic>{
        'cookidoo_ids': cookidooIds,
      };
      final d = day ?? DateTime.now();
      final local = d.toLocal();
      body['day'] =
          '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
      await _dio.post(Endpoints.cookidooPlanDay, data: body);
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

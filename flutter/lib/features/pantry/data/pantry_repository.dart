import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/pantry_item.dart';

class PantryRepository {
  final Dio _dio;

  PantryRepository(this._dio);

  Future<List<PantryItem>> getItems({
    String? category,
    String? search,
    String sort = 'category',
    String order = 'asc',
  }) async {
    try {
      final params = <String, dynamic>{
        'sort': sort,
        'order': order,
      };
      if (category != null && category.trim().isNotEmpty) params['category'] = category.trim();
      if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
      final response =
          await _dio.get(Endpoints.pantry, queryParameters: params);
      return (response.data as List)
          .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PantryItem> addItem(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.pantry, data: data);
      return PantryItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<PantryItem>> addBulk(List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post(
        Endpoints.pantryBulk,
        data: {'items': items},
      );
      return (response.data as List)
          .map((e) => PantryItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PantryItem> updateItem(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(Endpoints.pantryItem(id), data: data);
      return PantryItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dio.delete(Endpoints.pantryItem(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<PantryAlert>> getAlerts() async {
    try {
      final response = await _dio.get(Endpoints.pantryAlerts);
      return (response.data as List)
          .map((e) => PantryAlert.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> addAlertToShopping(int alertId) async {
    try {
      await _dio.post(Endpoints.pantryAlertAddToShopping(alertId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> dismissAlert(int alertId) async {
    try {
      await _dio.post(Endpoints.pantryAlertDismiss(alertId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final pantryRepositoryProvider = Provider<PantryRepository>((ref) {
  return PantryRepository(ref.watch(dioProvider));
});

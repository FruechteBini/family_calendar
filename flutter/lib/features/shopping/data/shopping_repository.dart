import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/shopping.dart';

class ShoppingRepository {
  final Dio _dio;

  ShoppingRepository(this._dio);

  Future<ShoppingList?> getList() async {
    try {
      final response = await _dio.get(Endpoints.shoppingList);
      final data = response.data;
      if (data == null) return null;
      return ShoppingList.fromJson(data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ShoppingList> generate({DateTime? weekStart}) async {
    try {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final d = weekStart ?? monday;
      final weekStartStr =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final response = await _dio.post(
        Endpoints.shoppingGenerate,
        data: {'week_start': weekStartStr},
      );
      return ShoppingList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ShoppingItem> addItem(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.shoppingItems, data: data);
      return ShoppingItem.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> checkItem(int id, {required bool checked}) async {
    try {
      await _dio.patch(Endpoints.shoppingItemCheck(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteItem(int id) async {
    try {
      await _dio.delete(Endpoints.shoppingItemDelete(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ShoppingList> aiSort() async {
    try {
      final response = await _dio.post(Endpoints.shoppingSort);
      return ShoppingList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> clearAll() async {
    try {
      await _dio.post(Endpoints.shoppingClearAll);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(dioProvider));
});

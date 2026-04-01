import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/shopping.dart';

class ShoppingRepository {
  final Dio _dio;

  ShoppingRepository(this._dio);

  Future<ShoppingList> getList() async {
    try {
      final response = await _dio.get(Endpoints.shoppingList);
      return ShoppingList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<ShoppingList> generate({int? weekOffset}) async {
    try {
      final data = <String, dynamic>{};
      if (weekOffset != null) data['week'] = weekOffset;
      final response = await _dio.post(Endpoints.shoppingGenerate, data: data);
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
      await _dio.patch(
        Endpoints.shoppingItemCheck(id),
        data: {'checked': checked},
      );
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

  Future<ShoppingList> aiSort(int listId) async {
    try {
      final response = await _dio.post(Endpoints.shoppingSort);
      return ShoppingList.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(dioProvider));
});

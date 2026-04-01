import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/knuspr.dart';

class KnusprRepository {
  final Dio _dio;

  KnusprRepository(this._dio);

  Future<List<KnusprProduct>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        Endpoints.knusprProductSearch,
        queryParameters: {'q': query},
      );
      return (response.data as List)
          .map((e) => KnusprProduct.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    try {
      await _dio.post(
        Endpoints.knusprCartAdd,
        data: {'product_id': productId, 'quantity': quantity},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> sendShoppingList(int listId) async {
    try {
      await _dio.post(Endpoints.knusprCartSendList(listId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<KnusprDeliverySlot>> getDeliverySlots() async {
    try {
      final response = await _dio.get(Endpoints.knusprDeliverySlots);
      return (response.data as List)
          .map((e) => KnusprDeliverySlot.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete(Endpoints.knusprCart);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final knusprRepositoryProvider = Provider<KnusprRepository>((ref) {
  return KnusprRepository(ref.watch(dioProvider));
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/knuspr.dart';

class KnusprRepository {
  final Dio _dio;

  KnusprRepository(this._dio);

  Future<KnusprStatus> getStatus() async {
    try {
      final response = await _dio.get(Endpoints.knusprStatus);
      return KnusprStatus.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

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

  Future<KnusprSendResult> sendShoppingList(int listId) async {
    try {
      final response =
          await _dio.post(Endpoints.knusprCartSendList(listId));
      return KnusprSendResult.fromJson(response.data as Map<String, dynamic>);
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

  Future<KnusprCartSnapshot> getCart() async {
    try {
      final response = await _dio.get(Endpoints.knusprCartGet);
      return KnusprCartSnapshot.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> removeCartLine(String orderFieldId) async {
    try {
      await _dio.delete(Endpoints.knusprCartItem(orderFieldId));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<PreviewShoppingListPayload> previewShoppingList(int listId) async {
    try {
      final response = await _dio.post(Endpoints.knusprPreviewList(listId));
      return PreviewShoppingListPayload.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<KnusprSendResult> applySelections(
    int listId,
    List<Map<String, dynamic>> selections,
  ) async {
    try {
      final response = await _dio.post(
        Endpoints.knusprApplySelections(listId),
        data: {'selections': selections},
      );
      return KnusprSendResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Map<String, dynamic>> priceCheck(List<Map<String, dynamic>> items) async {
    try {
      final response = await _dio.post(
        Endpoints.knusprPriceCheck,
        data: {'items': items},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> bookDeliverySlot(String slotId) async {
    try {
      final response = await _dio.post(
        Endpoints.knusprBookSlot,
        data: {'slot_id': slotId},
      );
      final data = response.data as Map<String, dynamic>?;
      if (data != null && data['success'] != true) {
        throw ApiException(
          data['message']?.toString() ?? 'Lieferslot konnte nicht gebucht werden',
        );
      }
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<KnusprMapping>> getMappings() async {
    try {
      final response = await _dio.get(Endpoints.knusprMappings);
      return (response.data as List)
          .map((e) => KnusprMapping.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteMapping(int id) async {
    try {
      await _dio.delete(Endpoints.knusprMapping(id));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final knusprRepositoryProvider = Provider<KnusprRepository>((ref) {
  return KnusprRepository(ref.watch(dioProvider));
});

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/meal_plan.dart';

class MealRepository {
  final Dio _dio;

  MealRepository(this._dio);

  Future<MealPlan> getWeekPlan({int? weekOffset}) async {
    try {
      final params = <String, dynamic>{};
      if (weekOffset != null) params['week'] = weekOffset;
      final response = await _dio.get(
        Endpoints.mealsPlan,
        queryParameters: params,
      );
      return MealPlan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> setSlot(String date, String slot, int recipeId) async {
    try {
      await _dio.put(
        Endpoints.mealSlot(date, slot),
        data: {'recipe_id': recipeId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> clearSlot(String date, String slot) async {
    try {
      await _dio.delete(Endpoints.mealSlot(date, slot));
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  /// Leert alle Slots der Kalenderwoche, in die [weekAnchor] fällt (Mo–So).
  Future<void> clearWeekPlan({String? weekAnchor}) async {
    try {
      await _dio.delete(
        Endpoints.mealsPlan,
        queryParameters:
            weekAnchor != null ? <String, dynamic>{'week': weekAnchor} : null,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> markCooked(
    String date,
    String slot, {
    int? rating,
    String? difficulty,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (rating != null) data['rating'] = rating;
      if (difficulty != null) data['difficulty'] = difficulty;
      await _dio.patch(Endpoints.mealSlotDone(date, slot), data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepository(ref.watch(dioProvider));
});

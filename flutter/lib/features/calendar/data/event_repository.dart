import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/endpoints.dart';
import '../domain/event.dart';

class EventRepository {
  final Dio _dio;

  EventRepository(this._dio);

  Future<Event> getEvent(int id, {DateTime? occurrenceStart}) async {
    try {
      final qp = <String, dynamic>{};
      if (occurrenceStart != null) {
        qp['occurrence_start'] = occurrenceStart.toUtc().toIso8601String();
      }
      final response = await _dio.get(
        Endpoints.event(id),
        queryParameters: qp.isEmpty ? null : qp,
      );
      return Event.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<List<Event>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
    int? categoryId,
  }) async {
    try {
      final params = <String, dynamic>{};
      if (startDate != null) params['date_from'] = startDate.toIso8601String();
      if (endDate != null) params['date_to'] = endDate.toIso8601String();
      if (categoryId != null) params['category_id'] = categoryId;

      final response = await _dio.get(
        Endpoints.events,
        queryParameters: params,
      );
      return (response.data as List)
          .map((e) => Event.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Event> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(Endpoints.events, data: data);
      return Event.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<Event> updateEvent(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(Endpoints.event(id), data: data);
      return Event.fromJson(response.data);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      // API returns 204 No Content — avoid default JSON decode on empty body.
      await _dio.delete(
        Endpoints.event(id),
        options: Options(responseType: ResponseType.plain),
      );
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }
}

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(dioProvider));
});

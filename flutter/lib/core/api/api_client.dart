import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_interceptor.dart';
import '../auth/auth_provider.dart';

final dioProvider = Provider<Dio>((ref) {
  final authState = ref.watch(authStateProvider);
  final serverUrl = ref.watch(serverUrlProvider);

  final dio = Dio(BaseOptions(
    baseUrl: serverUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 60),
    sendTimeout: const Duration(seconds: 60),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(
    token: authState.token,
    onUnauthorized: () => ref.read(authStateProvider.notifier).logout(),
  ));

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (o) {},
  ));

  return dio;
});

final serverUrlProvider = StateProvider<String>((ref) => 'http://localhost:8000');

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException(this.message, {this.statusCode, this.data});

  factory ApiException.fromDioError(DioException e) {
    final response = e.response;
    if (response != null) {
      final data = response.data;
      String message = 'Fehler';
      if (data is Map<String, dynamic> && data.containsKey('detail')) {
        message = data['detail'].toString();
      } else {
        message = 'HTTP ${response.statusCode}';
      }
      return ApiException(message, statusCode: response.statusCode, data: data);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Zeitueberschreitung bei der Verbindung');
      case DioExceptionType.connectionError:
        return ApiException('Keine Verbindung zum Server');
      default:
        return ApiException(e.message ?? 'Unbekannter Fehler');
    }
  }

  @override
  String toString() => message;
}

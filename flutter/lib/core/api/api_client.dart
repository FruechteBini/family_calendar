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

  // Capture the token at Dio creation time so we can detect stale 401s
  final capturedToken = authState.token;
  dio.interceptors.add(AuthInterceptor(
    token: capturedToken,
    onUnauthorized: () {
      // Only logout if the token hasn't changed since this Dio was created.
      // Prevents stale in-flight requests from logging out after re-login.
      final currentToken = ref.read(authStateProvider).token;
      if (currentToken == capturedToken) {
        ref.read(authStateProvider.notifier).logout();
      }
    },
  ));

  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
    logPrint: (o) {},
  ));

  return dio;
});

/// Production NAS (Synology). Override via Login → „Server konfigurieren“ or secure storage.
const kDefaultServerUrl = 'https://blanzis.synology.me';

final serverUrlProvider = StateProvider<String>((ref) => kDefaultServerUrl);

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
        final detail = data['detail'];
        if (detail is String) {
          message = detail;
        } else if (detail is List) {
          // FastAPI/Pydantic validation errors: [{"loc":["query","week_start"],"msg":"Field required",...}, ...]
          final parts = <String>[];
          for (final item in detail) {
            if (item is Map) {
              final loc = item['loc'];
              final msg = item['msg'];
              final locStr = loc is List ? loc.join('.') : loc?.toString();
              if (locStr != null && msg != null) {
                parts.add('$locStr: $msg');
              }
            }
          }
          message = parts.isNotEmpty ? parts.join(' · ') : detail.toString();
        } else {
          message = detail.toString();
        }
      } else {
        message = 'HTTP ${response.statusCode}';
      }
      return ApiException(message, statusCode: response.statusCode, data: data);
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Zeitüberschreitung bei der Verbindung');
      case DioExceptionType.connectionError:
        return ApiException('Keine Verbindung zum Server');
      default:
        return ApiException(e.message ?? 'Unbekannter Fehler');
    }
  }

  @override
  String toString() => message;
}

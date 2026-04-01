import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  final String? token;
  final VoidCallback onUnauthorized;

  AuthInterceptor({required this.token, required this.onUnauthorized});

  static const _publicPaths = ['/api/auth/login', '/api/auth/register'];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = _publicPaths.any((p) => options.path.endsWith(p));
    if (!isPublic && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      final isLogin = _publicPaths.any((p) => err.requestOptions.path.endsWith(p));
      if (!isLogin) {
        onUnauthorized();
      }
    }
    handler.next(err);
  }
}

typedef VoidCallback = void Function();

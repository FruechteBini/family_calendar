import 'package:dio/dio.dart';

typedef VoidCallback = void Function();
typedef TokenRenewer = Future<String?> Function();

class AuthInterceptor extends Interceptor {
  final String? token;
  final VoidCallback onUnauthorized;
  final TokenRenewer? onTryRenew;

  AuthInterceptor({
    required this.token,
    required this.onUnauthorized,
    this.onTryRenew,
  });

  static const _publicPaths = ['/api/auth/login', '/api/auth/register'];
  static const _renewPath = '/api/auth/renew';

  /// Shared future so concurrent 401s only trigger one renewal attempt.
  static Future<String?>? _renewFuture;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final isPublic = _publicPaths.any((p) => options.path.endsWith(p));
    if (!isPublic && token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode != 401 || token == null) {
      return handler.next(err);
    }

    final isLogin = _publicPaths.any((p) => err.requestOptions.path.endsWith(p));
    final isRenew = err.requestOptions.path.endsWith(_renewPath);
    if (isLogin || isRenew) {
      return handler.next(err);
    }

    if (onTryRenew != null) {
      try {
        _renewFuture ??= onTryRenew!();
        final newToken = await _renewFuture;
        _renewFuture = null;

        if (newToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final retryDio = Dio(BaseOptions(
            baseUrl: opts.baseUrl,
            connectTimeout: opts.connectTimeout,
            receiveTimeout: opts.receiveTimeout,
            sendTimeout: opts.sendTimeout,
          ));
          final response = await retryDio.fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {
        _renewFuture = null;
      }
    }

    onUnauthorized();
    handler.next(err);
  }
}

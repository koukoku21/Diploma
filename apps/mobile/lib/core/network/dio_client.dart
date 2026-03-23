import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _baseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://10.0.2.2:3000/api/v1', // Android emulator → localhost
);

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.add(_AuthInterceptor(dio));

  return dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._dio);

  final Dio _dio;
  final _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 || _isRefreshing) {
      handler.next(err);
      return;
    }

    // Пробуем обновить токен
    _isRefreshing = true;
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null) {
        _clearTokens();
        handler.next(err);
        return;
      }

      // Запрос к refresh без interceptor (чтобы не зациклиться)
      final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess  = res.data['accessToken']  as String;
      final newRefresh = res.data['refreshToken'] as String;

      await Future.wait([
        _storage.write(key: 'access_token',  value: newAccess),
        _storage.write(key: 'refresh_token', value: newRefresh),
      ]);

      // Повторяем оригинальный запрос с новым токеном
      final opts = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess';
      final response = await _dio.fetch(opts);
      handler.resolve(response);
    } catch (_) {
      _clearTokens();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _clearTokens() async {
    await _storage.deleteAll();
  }
}

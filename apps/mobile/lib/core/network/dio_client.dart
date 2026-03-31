import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

String get apiBaseUrl {
  const envUrl = String.fromEnvironment('API_URL');
  if (envUrl.isNotEmpty) return envUrl;

  if (kIsWeb) return 'http://localhost:4040/api/v1';
  if (Platform.isAndroid) return 'http://10.0.2.2:4040/api/v1';
  return 'http://localhost:4040/api/v1';
}

String get socketBaseUrl {
  const envUrl = String.fromEnvironment('SOCKET_URL');
  if (envUrl.isNotEmpty) return envUrl;

  if (kIsWeb) return 'http://localhost:4040';
  if (Platform.isAndroid) return 'http://10.0.2.2:4040';
  return 'http://localhost:4040';
}

Dio createDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
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
  final _storage = TokenStorage();
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
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
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        _clearTokens();
        handler.next(err);
        return;
      }

      // Запрос к refresh без interceptor (чтобы не зациклиться)
      final refreshDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final res = await refreshDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccess  = res.data['accessToken']  as String;
      final newRefresh = res.data['refreshToken'] as String;

      await _storage.saveTokens(newAccess, newRefresh);

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

  Future<void> _clearTokens() => _storage.clear();
}

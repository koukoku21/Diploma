import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<void> sendOtp(String phone) async {
    await _dio.post('/auth/send-otp', data: {'phone': phone});
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    final res = await _dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'code': code,
      if (name != null) 'name': name,
    });
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final res = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return res.data as Map<String, dynamic>;
  }
}

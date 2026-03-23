import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final AuthApi _api;
  final FlutterSecureStorage _storage;

  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> sendOtp(String phone) => _api.sendOtp(phone);

  /// Возвращает isNewUser — true если нужен экран A-4 (ввод имени)
  Future<({bool isNewUser})> verifyOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    final data = await _api.verifyOtp(phone: phone, code: code, name: name);
    await _saveTokens(data['accessToken'], data['refreshToken']);
    return (isNewUser: data['isNewUser'] as bool);
  }

  Future<void> refresh() async {
    final token = await _storage.read(key: _refreshKey);
    if (token == null) throw Exception('Нет refresh токена');
    final data = await _api.refresh(token);
    await _saveTokens(data['accessToken'], data['refreshToken']);
  }

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);
  Future<bool> isLoggedIn() async => (await getAccessToken()) != null;

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await Future.wait([
      _storage.write(key: _accessKey, value: access),
      _storage.write(key: _refreshKey, value: refresh),
    ]);
  }
}

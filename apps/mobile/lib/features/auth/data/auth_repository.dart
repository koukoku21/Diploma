import '../../../core/auth/token_storage.dart';
import 'auth_api.dart';

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final AuthApi _api;
  final TokenStorage _storage;

  Future<void> sendOtp(String phone) => _api.sendOtp(phone);

  /// Возвращает isNewUser — true если нужен экран A-4 (ввод имени)
  Future<({bool isNewUser})> verifyOtp({
    required String phone,
    required String code,
    String? name,
  }) async {
    final data = await _api.verifyOtp(phone: phone, code: code, name: name);
    await _storage.saveTokens(data['accessToken'], data['refreshToken']);
    return (isNewUser: data['isNewUser'] as bool);
  }

  Future<void> refresh() async {
    final token = await _storage.getRefreshToken();
    if (token == null) throw Exception('Нет refresh токена');
    final data = await _api.refresh(token);
    await _storage.saveTokens(data['accessToken'], data['refreshToken']);
  }

  Future<String?> getAccessToken() => _storage.getAccessToken();
  Future<bool> isLoggedIn() => _storage.isLoggedIn();

  Future<void> logout() => _storage.clear();
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web: SharedPreferences (localStorage) — no WebCrypto issues in dev
/// Native: FlutterSecureStorage (Keychain / Keystore)
class TokenStorage {
  static const _accessKey  = 'access_token';
  static const _refreshKey = 'refresh_token';

  final _secure = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  Future<String?> getAccessToken()  => _read(_accessKey);
  Future<String?> getRefreshToken() => _read(_refreshKey);

  Future<void> saveTokens(String access, String refresh) async {
    await Future.wait([_write(_accessKey, access), _write(_refreshKey, refresh)]);
  }

  Future<bool> isLoggedIn() async => (await getAccessToken()) != null;

  Future<void> clear() async {
    if (kIsWeb) {
      final p = await _p;
      await Future.wait([p.remove(_accessKey), p.remove(_refreshKey)]);
    } else {
      await _secure.deleteAll();
    }
  }

  Future<String?> _read(String key) async {
    if (kIsWeb) return (await _p).getString(key);
    return _secure.read(key: key);
  }

  Future<void> _write(String key, String value) async {
    if (kIsWeb) {
      await (await _p).setString(key, value);
    } else {
      await _secure.write(key: key, value: value);
    }
  }
}

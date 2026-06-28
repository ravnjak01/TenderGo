import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthTokenStore {
  static const accessTokenKey = 'jwt_token';
  static const refreshTokenKey = 'refresh_token';

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  const AuthTokenStore();

  Future<String?> readAccessToken() => _storage.read(key: accessTokenKey);

  Future<String?> readRefreshToken() => _storage.read(key: refreshTokenKey);

  Future<bool> hasValidAccessToken() async {
    final token = await readAccessToken();
    if (token == null || token.trim().isEmpty) return false;
    if (token.split('.').length != 3) return false;

    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await clear();

    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: refreshTokenKey, value: refreshToken);
    }

    await _storage.write(key: accessTokenKey, value: accessToken);
  }

  Future<void> updateTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: refreshTokenKey, value: refreshToken);
    }

    await _storage.write(key: accessTokenKey, value: accessToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
  }

  Future<void> clearAccessToken() => _storage.delete(key: accessTokenKey);
}

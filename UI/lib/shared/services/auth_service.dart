import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';

class AuthService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  AuthService(this._dio);

  // 1. Prijava (Login)
  Future<bool> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        String? token = response.data['token'];

        if (token == null) {
          return false;
        }

        await _storage.write(key: 'jwt_token', value: token);
        return true;
      }
      return false;
    } on DioException catch (_) {
      return false;
    }
  }

  // 2. Odjava (Logout)
  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  // 3. Provera da li je korisnik ulogovan
  static Future<bool> isLoggedIn() async {
    String? token = await _storage.read(key: 'jwt_token');

    if (token == null) {
      return false;
    }

    bool isTokenExpired = JwtDecoder.isExpired(token);

    if (isTokenExpired) {
      await _storage.delete(key: 'jwt_token');
      return false;
    }

    return true;
  }

  static Future<String?> getCurrentUserId() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty || JwtDecoder.isExpired(token)) {
      return null;
    }

    final claims = JwtDecoder.decode(token);
    const candidateKeys = <String>[
      'nameid',
      'sub',
      'userId',
      'userid',
      'id',
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
    ];

    for (final key in candidateKeys) {
      final value = claims[key];
      if (value == null) continue;
      final normalized = value.toString().trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    return null;
  }

  //4.Registracija (Registration)
  Future<bool> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: request.toJson(),
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (_) {
      return false;
    }
  }

  // 5. Forgot Password
  Future<AuthResult> forgotPassword(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
      return const AuthResult(
        success: true,
        message: 'If this email exists, a reset link was sent.',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map)
          ? (data['message']?.toString() ?? 'Something went wrong.')
          : 'Something went wrong.';

      return AuthResult(success: false, message: message);
    }
  }

  // 6. Reset Password
  Future<AuthResult> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: request.toJson());
      return const AuthResult(
        success: true,
        message: 'Password reset successfully.',
      );
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        message: e.response?.data['message'] ?? 'Something went wrong.',
      );
    }
  }

  Future<AuthResult> getCurrentUser() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.me,
        options: await _options(),
      );
      final data = response.data;
      final payload = data is Map<String, dynamic>
          ? (data['result'] is Map<String, dynamic>
                ? data['result'] as Map<String, dynamic>
                : data['data'] is Map<String, dynamic>
                ? data['data'] as Map<String, dynamic>
                : data)
          : null;
      final user = payload != null ? UserDto.fromJson(payload) : null;

      return AuthResult(
        success: user != null,
        message: user != null
            ? 'User data retrieved successfully.'
            : 'Invalid user payload.',
        data: user,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map)
          ? (data['message']?.toString() ?? 'Something went wrong.')
          : 'Something went wrong.';

      return AuthResult(success: false, message: message);
    }
  }

  Future<Options> _options() async {
    final token = await _storage.read(key: 'jwt_token');
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }
}

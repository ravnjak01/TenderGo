import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/error/error_handler.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tendergo/shared/models/dto/address_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/login_request.dart';
import 'package:tendergo/shared/models/requests/register_request.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';

class AuthService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  AuthService(this._dio);

  // 1. Prijava (Login)
  Future<AuthResult<void>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final token = response.data['token']?.toString();

        if (token == null || token.isEmpty) {
          return AuthResult.failure('Invalid response from server.');
        }

        await _storage.write(key: 'jwt_token', value: token);
        return AuthResult.success(null);
      }
      return AuthResult.failure('Sign in not successful. Please check your credentials.');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (ErrorHandler.isAccountBanned(data)) {
        return AuthResult.failure(ErrorHandler.accountBannedMessage());
      }
      final message = ErrorHandler.extractErrorMessage(data);
      return AuthResult.failure(
        message ?? 'Wrong email or password.',
      );
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
  //4. getCurrentUser

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

  //5.Registracija (Registration)
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

  // 6. Forgot Password
  Future<AuthResult> forgotPassword(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
      return  AuthResult(
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

  // 7. Reset Password
  Future<AuthResult> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: request.toJson());
      return  AuthResult(
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

Future<bool> refreshToken() async {
    try {
      final storedRefresh = await _storage.read(key: 'refresh_token');
      if (storedRefresh == null || storedRefresh.isEmpty) return false;
 
      // Bypass the interceptor to avoid an infinite refresh loop.
      final plainDio = Dio(_dio.options);
      final response = await plainDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': storedRefresh},
      );
 
      if (response.statusCode == 200) {
        final newToken = response.data['token']?.toString();
        final newRefresh = response.data['refreshToken']?.toString();
 
        if (newToken == null || newToken.isEmpty) {
          await logout();
          return false;
        }
 
        await _storage.write(key: 'jwt_token', value: newToken);
        if (newRefresh != null && newRefresh.isNotEmpty) {
          await _storage.write(key: 'refresh_token', value: newRefresh);
        }
        return true;
      }
 
      await logout();
      return false;
    } on DioException catch (_) {
      await logout();
      return false;
    }
  }

  Future<AuthResult> getCurrentUser() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.me,
        options: await _options(),
      );
      final data = response.data;
      final payload = _extractUserPayload(data);
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

  Map<String, dynamic>? _extractUserPayload(dynamic data) {
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final directCandidates = <dynamic>[
      data['result'],
      data['data'],
      data['user'],
      data['User'],
      data,
    ];

    for (final candidate in directCandidates) {
      if (candidate is! Map) continue;
      final map = candidate is Map<String, dynamic>
          ? candidate
          : candidate.map((key, value) => MapEntry(key.toString(), value));

      final nestedUser =
          map['user'] ?? map['User'] ?? map['result'] ?? map['data'];
      if (nestedUser is Map<String, dynamic>) {
        return nestedUser;
      }
      if (nestedUser is Map) {
        return nestedUser.map((key, value) => MapEntry(key.toString(), value));
      }

      if (map.containsKey('email') ||
          map.containsKey('userName') ||
          map.containsKey('username')) {
        return map;
      }
    }

    return null;
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

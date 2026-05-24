import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/error/error_handler.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tendergo/shared/models/dto/address_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/login_request.dart';
import 'package:tendergo/shared/models/requests/register_request.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';
import 'package:tendergo/shared/services/api_helper.dart';

class AuthService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  AuthService(this._dio);

  // 1. Prijava (Login)
  Future<ApiResponse<void>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {

        if (response.data == null || response.data is! Map) {
        return ApiResponse.failure('Server returned an empty or invalid response.');
      }

        final token = response.data['token']?.toString();

        if (token == null || token.isEmpty) {
          return ApiResponse.failure('Invalid response from server.');
        }

        await _storage.write(key: 'jwt_token', value: token);
        return ApiResponse.success(null);
      }
      return ApiResponse.failure('Sign in not successful. Please check your credentials.');
    } on DioException catch (e) {
      final data = e.response?.data;
      if (ErrorHandler.isAccountBanned(data)) {
        return ApiResponse.failure(ErrorHandler.accountBannedMessage());
      }
      final message = ErrorHandler.extractErrorMessage(data);
      return ApiResponse.failure(
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
 Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      await _dio.post(ApiEndpoints.forgotPassword, data: {'email': email});
      
      // Koristimo novi konstruktor za uspjeh (data je null)
      return ApiResponse.success(
        null, 
      );
    } on DioException catch (e) {
      // Prepustamo ApiHelper-u da izvuče poruku i tačan status kod
      return ApiHelper.handleDioError<void>(e);
    }
  }

  // 7. Reset Password
  Future<ApiResponse<void>> resetPassword(ResetPasswordRequest request) async {
  try {
    await _dio.post(ApiEndpoints.resetPassword, data: request.toJson());
    
    return ApiResponse.success(
      null, 
      message: 'Password reset successfully.',
    );
  } on DioException catch (e) {
    if (e.response != null && e.response?.data != null) {
      final data = e.response!.data;

      if (data is Map && data['errors'] != null && (data['errors'] as List).isNotEmpty) {
        final firstError = data['errors'][0].toString();
        
        return ApiResponse.failure(
           firstError, 
        );
      }
    }

    // Ako struktura nije onakva kakvu očekujemo, pusti stari helper da odradi fallback
    return ApiHelper.handleDioError<void>(e);
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

 Future<ApiResponse<UserDto?>> getCurrentUser() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.me,
        options: await _options(),
      );
      final data = response.data;

      if (data == null) {
      return ApiResponse.failure('Empty response from server.', statusCode: 500);
    }

    // ✅ Guard wrong type
    if (data is! Map<String, dynamic>) {
      return ApiResponse.failure('Unexpected response format.', statusCode: 500);
    }
    
      final payload = _extractUserPayload(data);
      final user = payload != null ? UserDto.fromJson(payload) : null;

      if (user != null) {
        // Koristimo novi konstruktor za uspjeh (statusCode se automatski postavlja na 200)
        return ApiResponse.success(
          user, 
          message: 'User data retrieved successfully.',
        );
      } else {
        // Ako je payload bio nevalidan, vraćamo failure sa status kodom 400
        return ApiResponse.failure(
          'Invalid user payload.', 
          statusCode: 400,
        );
      }
    } on DioException catch (e) {
      // Umjesto ručnog pisanja logike za grešku, iskoristi ApiHelper koji smo upravo sredili!
      return ApiHelper.handleDioError<UserDto?>(e);
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

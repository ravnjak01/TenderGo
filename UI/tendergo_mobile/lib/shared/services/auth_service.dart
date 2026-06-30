import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tendergo/shared/core/auth/auth_token_store.dart';
import 'package:tendergo/shared/core/error/error_handler.dart';
import 'package:tendergo/shared/core/network/constants/multiple_endpoints.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/login_request.dart';
import 'package:tendergo/shared/models/requests/register_request.dart';
import 'package:tendergo/shared/models/requests/reset_password_request.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
import 'package:tendergo/shared/services/api_helper.dart';

class AuthService {
  final Dio _dio;
  static const AuthTokenStore _tokenStore = AuthTokenStore();

  AuthService(this._dio);

  Future<ApiResponse<void>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final envelope = response.data as Map<String, dynamic>?;
        final innerData = envelope?['data'] as Map<String, dynamic>?;

        final token = innerData?['token']?.toString();
        final refreshToken = innerData?['refreshToken']?.toString();

        if (token == null || token.isEmpty || token.split('.').length != 3) {
          return ApiResponse.failure('Invalid response from server.');
        }

        await _tokenStore.saveTokens(
          accessToken: token,
          refreshToken: refreshToken,
        );

        if (kDebugMode) {
          final saved = await _tokenStore.readAccessToken();
        
        }

        return ApiResponse.success(null);
      }

      return ApiResponse.failure(
        'Sign in not successful. Please check your credentials.',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (ErrorHandler.isAccountBanned(data)) {
        return ApiResponse.failure(ErrorHandler.accountBannedMessage());
      }
      final message = ErrorHandler.extractErrorMessage(data);
      return ApiResponse.failure(message ?? 'Wrong email or password.');
    }
  }

  Future<void> logout() async {
    await _tokenStore.clear();
  }

  static Future<bool> isLoggedIn() => _tokenStore.hasValidAccessToken();

  static Future<String?> getCurrentUserId() async {
    final token = await _tokenStore.readAccessToken();
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

Future<ApiResponse<void>> forgotPassword(String email) async {
  try {
    final response = await _dio.post(
      ApiEndpoints.forgotPassword,
      data: {'email': email},
    );

    return ApiResponse<void>.fromJson(response.data);
  } on DioException catch (e) {
    return ApiHelper.handleDioError<void>(e);
  }
}

  Future<ApiResponse<void>> resetPassword(ResetPasswordRequest request) async {
    try {
      await _dio.post(ApiEndpoints.resetPassword, data: request.toJson());

      return ApiResponse.success(null, message: 'Password reset successfully.');
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response!.data;

        if (data is Map &&
            data['errors'] != null &&
            (data['errors'] as List).isNotEmpty) {
          final firstError = data['errors'][0].toString();

          return ApiResponse.failure(firstError);
        }
      }

      return ApiHelper.handleDioError<void>(e);
    }
  }

  Future<bool> refreshToken() async {
    try {
      final storedRefresh = await _tokenStore.readRefreshToken();
      if (storedRefresh == null || storedRefresh.isEmpty) return false;

      final plainDio = Dio(_dio.options);
      final response = await plainDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': storedRefresh},
      );

      if (response.statusCode == 200) {
        final innerData =
            (response.data as Map<String, dynamic>?)?['data']
                as Map<String, dynamic>?;
        final newToken = innerData?['token']?.toString();
        final newRefresh = innerData?['refreshToken']?.toString();

        if (newToken == null || newToken.isEmpty) {
          await logout();
          return false;
        }

        await _tokenStore.updateTokens(
          accessToken: newToken,
          refreshToken: newRefresh,
        );
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
    if (!await _tokenStore.hasValidAccessToken()) {
      return ApiResponse.failure('Not authenticated.', statusCode: 401);
    }

    try {
      final response = await _dio.get(ApiEndpoints.me);

      final data =
          (response.data as Map<String, dynamic>)['data']
              as Map<String, dynamic>?;

      if (data == null) {
        return ApiResponse.failure('Empty user payload.', statusCode: 500);
      }

      return ApiResponse.success(
        UserDto.fromJson(data),
        message: 'User data retrieved successfully.',
      );
    } on DioException catch (e) {
      return ApiHelper.handleDioError<UserDto?>(e);
    }
  }
}

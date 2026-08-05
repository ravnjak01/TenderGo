import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tendergo/shared/core/error/error_handler.dart';
import 'package:tendergo/shared/core/network/constants/auth_endpoints.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/login_request.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';

class AuthService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  AuthService(this._dio);

  Future<ApiResponse<void>> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: request.toJson(),
      );

      final envelope = response.data;

      if (envelope is! Map<String, dynamic>) {
        return ApiResponse.failure(
          'Invalid response from server.',
          statusCode: response.statusCode ?? 500,
        );
      }

      final data = envelope['data'];
      if (data is! Map<String, dynamic>) {
        return ApiResponse.failure(
          'Invalid data format from server.',
          statusCode: response.statusCode ?? 500,
        );
      }

      final token = data['token']?.toString();

      if (token == null || token.isEmpty) {
        return ApiResponse.failure(
          'Token was not returned from server.',
          statusCode: response.statusCode ?? 500,
        );
      }

      await _storage.write(key: 'jwt_token', value: token);

      final refreshToken = data['refreshToken']?.toString();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: refreshToken);
      }

      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError<void>(e);
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');
  }

  static Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'jwt_token');

    if (token == null || token.isEmpty) {
      return false;
    }

    if (JwtDecoder.isExpired(token)) {
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
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

    final userId = claims[
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'
    ]?.toString();

    if (userId == null || userId.trim().isEmpty) {
      return null;
    }

    return userId.trim();
  }

  Future<ApiResponse<void>> forgotPassword(String email) async {
    try {
      await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      return ApiResponse.success(null);
    } on DioException catch (e) {
      return _handleError<void>(e);
    }
  }

  Future<bool> refreshToken() async {
    try {
      final storedRefresh = await _storage.read(key: 'refresh_token');

      if (storedRefresh == null || storedRefresh.isEmpty) {
        return false;
      }

      final plainDio = Dio(_dio.options);

      final response = await plainDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': storedRefresh},
      );

      final envelope = response.data;

      if (envelope is! Map<String, dynamic>) {
        await logout();
        return false;
      }

      final data = envelope['data'];
      if (data is! Map<String, dynamic>) {
        await logout();
        return false;
      }

      final newToken = data['token']?.toString();
      final newRefresh = data['refreshToken']?.toString();

      if (newToken == null || newToken.isEmpty) {
        await logout();
        return false;
      }

      await _storage.write(key: 'jwt_token', value: newToken);

      if (newRefresh != null && newRefresh.isNotEmpty) {
        await _storage.write(key: 'refresh_token', value: newRefresh);
      }

      return true;
    } on DioException catch (_) {
      await logout();
      return false;
    }
  }

  Future<ApiResponse<UserDto>> getCurrentUser() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.me,
        options: await _options(),
      );

      final envelope = response.data;

      if (envelope is! Map<String, dynamic>) {
        return ApiResponse.failure(
          'Invalid response from server.',
          statusCode: response.statusCode ?? 500,
        );
      }

      final data = envelope['data'];
      if (data is! Map<String, dynamic>) {
        return ApiResponse.failure(
          'Invalid data format from server.',
          statusCode: response.statusCode ?? 500,
        );
      }

      final user = UserDto.fromJson(data);

      return ApiResponse.success(
        user,
        message: 'User data retrieved successfully.',
        statusCode: response.statusCode ?? 200,
      );
    } on DioException catch (e) {
      return _handleError<UserDto>(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException e) {
    final statusCode = e.response?.statusCode ?? 400;
    final data = e.response?.data;

    if (ErrorHandler.isAccountBanned(data)) {
      return ApiResponse.failure(
        ErrorHandler.accountBannedMessage(),
        statusCode: statusCode,
      );
    }

    final message = ErrorHandler.extractErrorMessage(data);

    return ApiResponse.failure(
      message ?? 'Greška u komunikaciji sa serverom.',
      statusCode: statusCode,
    );
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
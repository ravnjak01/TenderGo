import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:tendergo/shared/core/network/constants/admin_endpoints.dart';
import 'package:tendergo/shared/models/dto/admin_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/ui/auth_result.dart';
import 'package:tendergo/shared/services/api_helper.dart';

class AdminService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  AdminService(this._dio);

  Future<bool> isAdmin() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.me,
        options: await _options(),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return false;
      }

      final roles = data['roles'];
      if (roles is! List) {
        return false;
      }

      return roles.any((role) => role.toString().toLowerCase() == 'admin');
    } on DioException {
      return false;
    }
  }

  // 1. Get all users
  Future<AuthResult<List<UserDto>>> getAllUsers() async {
    try {
      final response = await _dio.get(
        AdminEndpoints.getAllUsers,
        options: await _options(),
      );

      final List<dynamic> data = response.data;
      final users = data.map((json) => UserDto.fromJson(json)).toList();

      return AuthResult.success(
      users,
        message: 'Users fetched successfully.',
      );
    } on DioException catch (e) {
      return ApiHelper.handleDioError<List<UserDto>>(e);
    }
  }

  // 2. Ban user
  Future<AuthResult> banUser(String userId, BanRequest reason) async {
    try {
      await _dio.post(
        AdminEndpoints.banUser(userId),
        data: reason.toJson(), // backend expects JSON with 'reason' field
        options: await _options(),
      );

      return  AuthResult(
        success: true,
        message: 'User banned successfully.',
      );
    } on DioException catch (e) {
      return ApiHelper.handleDioError(e);
    }
  }

  // 3. Unban user
  Future<AuthResult> unbanUser(String userId) async {
    try {
      await _dio.post(
        AdminEndpoints.unbanUser(userId),
        options: await _options(),
      );

      return  AuthResult(
        success: true,
        message: 'User unbanned successfully.',
      );
    } on DioException catch (e) {
      return ApiHelper.handleDioError(e);
    }
  }

  Future<AuthResult> deleteTender(int tenderId) async {
  try {
    await _dio.delete(
      AdminEndpoints.deleteTender(tenderId),
      options: await _options(),
    );

    return  AuthResult(
      success: true,
      message: 'Tender deleted successfully.',
    );
  } on DioException catch (e) {
    return ApiHelper.handleDioError(e);
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
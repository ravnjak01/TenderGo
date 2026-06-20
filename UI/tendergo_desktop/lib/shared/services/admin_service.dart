import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:tendergo/shared/core/network/constants/admin_endpoints.dart';
import 'package:tendergo/shared/models/dto/activity_dto.dart';
import 'package:tendergo/shared/models/dto/admin_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/ui/api_response.dart';
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

  Future<ApiResponse<List<UserDto>>> getAllUsers() async {
    try {
      final response = await _dio.get(
        AdminEndpoints.getAllUsers,
        options: await _options(),
      );

      final List<dynamic> data = response.data;
      final users = data.map((json) => UserDto.fromJson(json)).toList();

      return ApiResponse.success(users, message: 'Users fetched successfully.');
    } on DioException catch (e) {
      return ApiHelper.handleDioError<List<UserDto>>(e);
    }
  }

  Future<ApiResponse<List<TenderDto>>> getAllTenders() async {
    try {
      final response = await _dio.get(
        AdminEndpoints.getAllTenders,
        options: await _options(),
      );

      final List<dynamic> data = response.data;
      final tenders = data.map((json) => TenderDto.fromJson(json)).toList();

      return ApiResponse.success(tenders, message: 'Tenders fetched successfully.');
    } on DioException catch (e) {
      return ApiHelper.handleDioError<List<TenderDto>>(e);
    }
  }

  Future<ApiResponse<void>> banUser(String userId, BanRequest reason) async {
    try {
      await _dio.post(
        AdminEndpoints.banUser(userId),
        data: reason.toJson(),
        options: await _options(),
      );

      return ApiResponse.success(null, message: 'User banned successfully.');
    } on DioException catch (e) {
      return ApiHelper.handleDioError(e);
    }
  }

  Future<ApiResponse<void>> unbanUser(String userId) async {
    try {
      await _dio.post(
        AdminEndpoints.unbanUser(userId),
        options: await _options(),
      );

      return ApiResponse.success(null, message: 'User unbanned successfully.');
    } on DioException catch (e) {
      return ApiHelper.handleDioError(e);
    }
  }

Future<ApiResponse<List<ActivityDto>>> getRecentActivities() async {
    try {
      final response = await _dio.get(
        AdminEndpoints.recentActivity,
        options: await _options(),
      );

      final List<dynamic> data = response.data;
      final activities = data.map((json) => ActivityDto.fromJson(json)).toList();

      return ApiResponse.success(activities, message: 'Recent activities fetched successfully.');
    } on DioException catch (e) {
      return ApiHelper.handleDioError<List<ActivityDto>>(e);
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

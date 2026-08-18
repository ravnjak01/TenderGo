import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/admin_dashboard_endpoints.dart';
import 'package:tendergo/shared/core/network/constants/admin_users_endpoints.dart';
import 'package:tendergo/shared/core/network/constants/auth_endpoints.dart';
import 'package:tendergo/shared/models/dto/activity_dto.dart';
import 'package:tendergo/shared/models/dto/admin_dto.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/models/requests/admin_user_search_request.dart';
import 'package:tendergo/shared/models/requests/paged_search_request.dart';
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

      final envelope = response.data;
      if (envelope is! Map<String, dynamic>) {
        return false;
      }

      final data = envelope['data'];
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

  Future<AdminDashboardDto> getDashboard() async {
    try {
      final response = await _dio.get(
        AdminDashboardEndpoints.getDashboard,
        options: await _options(),
      );

      return AdminDashboardDto.fromJson(_extractObject(response.data));
    } on DioException catch (e) {
      throw Exception(
        ApiHelper.handleDioError(
          e,
          fallbackMessage: 'Error fetching dashboard',
        ).message,
      );
    }
  }

  Future<ApiResponse<PagedResult<UserDto>>> getAllUsers({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        AdminUserEndpoints.getAllUsers,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
        options: await _options(),
      );

      final apiResponse = ApiResponse<PagedResult<UserDto>>.fromJson(
        response.data as Map<String, dynamic>,
        dataParser: (dataJson) => PagedResult<UserDto>.fromJson(
          dataJson as Map<String, dynamic>,
          (userJson) => UserDto.fromJson(userJson),
        ),
      );

      return apiResponse;
    } on DioException catch (e) {
      return ApiHelper.handleDioError<PagedResult<UserDto>>(e);
    }
  }


  Future<ApiResponse<void>> banUser(String userId, BanRequest reason) async {
    try {
      await _dio.post(
        AdminUserEndpoints.banUser(userId),
        data: reason.toJson(),
        options: await _options(),
      );

      return ApiResponse.success(null, message: 'Korisnik blokiran uspješno.');
    } on DioException catch (e) {
      return ApiHelper.handleDioError(e);
    }
  }

  Future<ApiResponse<void>> unbanUser(String userId) async {
    try {
      await _dio.post(
        AdminUserEndpoints.unbanUser(userId),
        options: await _options(),
      );

      return ApiResponse.success(null, message: 'Korisnik odblokiran uspješno.');
    } on DioException catch (e) {
      return ApiHelper.handleDioError(e);
    }
  }

  Future<ApiResponse<List<ActivityDto>>> getRecentActivities() async {
    try {
      final response = await _dio.get(
        AdminDashboardEndpoints.getActivities,
        options: await _options(),
      );

      final data = _extractList(response.data);
      final activities = data
          .map((json) => ActivityDto.fromJson(json))
          .toList();

      return ApiResponse.success(
        activities,
        message: 'Recent activities fetched successfully.',
      );
    } on DioException catch (e) {
      return ApiHelper.handleDioError<List<ActivityDto>>(e);
    }
  }

  Future<PagedResult<UserDto>> search(AdminUserSearchRequest request) async {
    try {
      final response = await _dio.get(
        AdminUserEndpoints.searchUsers,
        options: await _options(),
        queryParameters: request.toJson(),
      );
      final envelope = response.data as Map<String, dynamic>;
      final pagedData = envelope['data'] as Map<String, dynamic>;

      return PagedResult<UserDto>.fromJson(
        pagedData,
        (json) => UserDto.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw Exception(
        ApiHelper.handleDioError(
          e,
          fallbackMessage: 'Error searching users',
        ).message,
      );
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

  List<dynamic> _extractList(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid response format.');
    }

    final data = responseData['data'];

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      final result = data['result'] ?? data['resultList'] ?? data['items'];
      if (result is List) {
        return result;
      }
    }

    throw Exception('Invalid response format: data is not a list.');
  }

  Map<String, dynamic> _extractObject(dynamic responseData) {
    if (responseData is! Map<String, dynamic>) {
      throw Exception('Invalid response format.');
    }

    final data = responseData['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }

    throw Exception('Invalid response format: data is not an object.');
  }
}
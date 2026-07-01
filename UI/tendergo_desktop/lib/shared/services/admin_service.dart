import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';
import 'package:tendergo/shared/core/network/constants/admin_endpoints.dart';
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
        AdminEndpoints.dashboard,
        options: await _options(),
      );

      return AdminDashboardDto.fromJson(_extractObject(response.data));
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching dashboard');
    }
  }

Future<ApiResponse<PagedResult<UserDto>>> getAllUsers({
  int page = 1, 
  int pageSize = 20,
}) async {
  try {
    final response = await _dio.get(
      AdminEndpoints.getAllUsers,
      // Prosljeđivanje parametara backendu kroz URL query (?page=1&pageSize=20)
      queryParameters: {
        'page': page,
        'pageSize': pageSize,
      },
      options: await _options(),
    );

    // Pretpostavka je da response.data direktno sadrži PagedResult objekat,
    // ili koristiš svoj _extractData ako imaš omotač na bazi cijelog API-ja.
    final dynamic responseData = response.data; 

    final pagedUsers = PagedResult<UserDto>.fromJson(
      responseData, 
      (json) => UserDto.fromJson(json as Map<String, dynamic>),
    );

    return ApiResponse.success(pagedUsers, message: 'Users fetched successfully.');
  } on DioException catch (e) {
    return ApiHelper.handleDioError<PagedResult<UserDto>>(e);
  }
}

  Future<ApiResponse<List<TenderDto>>> getAllTenders() async {
    try {
      final response = await _dio.get(
        AdminEndpoints.getAllTenders,
        options: await _options(),
      );

      final data = _extractList(response.data);
      final tenders = data.map((json) => TenderDto.fromJson(json)).toList();

      return ApiResponse.success(
        tenders,
        message: 'Tenders fetched successfully.',
      );
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
        AdminEndpoints.searchUsers,
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
      throw Exception(e.response?.data ?? 'Error searching users');
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

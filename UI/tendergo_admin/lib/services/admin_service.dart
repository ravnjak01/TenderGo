import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/network/constants/api_endpoints.dart';
import 'package:tendergo_admin/core/network/constants/admin_endpoints.dart';
import 'package:tendergo_admin/models/dto/admin_dto.dart';
import 'package:tendergo_admin/models/ui/auth_result.dart';

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
  Future<AuthResult> getAllUsers() async {
    try {
      final response = await _dio.get(
        AdminEndpoints.getAllUsers,
        options: await _options(),
      );

      return AuthResult(
        success: true,
        message: 'Users fetched successfully.',
        data: response.data,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map)
          ? (data['message']?.toString() ?? 'Something went wrong.')
          : 'Something went wrong.';

      return AuthResult(success: false, message: message);
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

      return const AuthResult(
        success: true,
        message: 'User banned successfully.',
      );
    } on DioException catch (e) {
      String errorMessage = 'Something went wrong.';
  
  if (e.response?.data != null && e.response?.data is Map) {
    final data = e.response!.data;
    
    // Provjerava da li backend šalje standardni Identity/Validation error
    if (data['errors'] != null) {
      // Ovo izvlači specifične greške poput "The reason field is required."
      var errors = data['errors'] as Map;
      errorMessage = errors.values.first[0].toString();
    } else {
      errorMessage = data['message']?.toString() ?? 'Something went wrong.';
    }
  }

   return AuthResult(success: false, message: errorMessage);
    }
  }

  // 3. Unban user
  Future<AuthResult> unbanUser(String userId) async {
    try {
      await _dio.post(
        AdminEndpoints.unbanUser(userId),
        options: await _options(),
      );

      return const AuthResult(
        success: true,
        message: 'User unbanned successfully.',
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map)
          ? (data['message']?.toString() ?? 'Something went wrong.')
          : 'Something went wrong.';

      return AuthResult(success: false, message: message);
    }
  }

  // 🔐 Shared options (Authorization header)
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

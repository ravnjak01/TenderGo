import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/network/constants/api_endpoints.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tendergo_admin/models/auth_result.dart';
class AuthService {
  final Dio _dio;
  static const _storage = const FlutterSecureStorage();

  AuthService(this._dio);

  // 1. Prijava (Login)
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post(ApiEndpoints.login, data: {
        'email': email,
        'password': password,
      });

   

      if (response.statusCode == 200) {
        String? token = response.data['Token'];

          if (token == null) {
            return false;
          }
        
        await _storage.write(key: 'jwt_token', value: token);
        return true;
      }
      return false;
    } on DioException catch (e) {
     
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

    bool isTokenExpired =JwtDecoder.isExpired(token);

    if (isTokenExpired) {
      await _storage.delete(key: 'jwt_token');
      return false;
    }

    return true;
  }

  //4.Registracija (Registration)
  Future<bool> register(String email, String password, String firstName, String lastName) async {
    try {
      final response = await _dio.post(ApiEndpoints.register, data: {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
      });

      print('Registration response status: ${response.statusCode}, data: ${response.data}');
      return response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300;
    } on DioException catch (e) {
      print("Error during registration: ${e.response?.data}");
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
    // Add these print statements
    print('=== FORGOT PASSWORD ERROR ===');
    print('Status code: ${e.response?.statusCode}');
    print('Response data: ${e.response?.data}');
    print('Response data type: ${e.response?.data.runtimeType}');
    print('Request URL: ${e.requestOptions.baseUrl}${e.requestOptions.path}');
    print('Request data: ${e.requestOptions.data}');
    print('Error type: ${e.type}');
    print('Error message: ${e.message}');
    print('=============================');

    final data = e.response?.data;
    final message = (data is Map)
        ? (data['message']?.toString() ?? 'Something went wrong.')
        : 'Something went wrong.';

    return AuthResult(success: false, message: message);
  }
}
// 6. Reset Password
Future<AuthResult> resetPassword(String token, String newPassword,String email) async {
  try {
    final response = await _dio.post(ApiEndpoints.resetPassword, data: {
      'token': token,
      'newPassword': newPassword,
      'email': email,
    });
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
  
}
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/network/constants/api_endpoints.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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

      return response.statusCode == 201; 
    } on DioException catch (e) {
      print("Error during registration: ${e.response?.data}");
      return false;
    }
  }
}
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/network/constants/api_endpoints.dart';

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
    // Ovde možeš dodati i jwt_decoder da proveriš da li je token istekao
    return token != null;
  }
}
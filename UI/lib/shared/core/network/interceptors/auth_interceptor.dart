import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart'; // Importuj svoje rute

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Proveri da li je ruta login ili register - za njih nam ne treba Bearer token
    if (options.path == ApiEndpoints.login || options.path == ApiEndpoints.register) {
      return handler.next(options);
    }

    // 2. Čitanje tokena
    final token = await _secureStorage.read(key: 'jwt_token');

    print("REQUEST: ${options.method} ${options.path}");
    print("TOKEN: $token");

    // 3. Dodavanje u header
      if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Ako backend vrati 401, to znači da je token istekao ili je nevažeći
      if (err.response?.statusCode == 401) {
      print("❌ UNAUTHORIZED - token invalid or expired");
    }
      
      // OVDE MOŽEŠ DODATI:
      // - Brisanje tokena: _secureStorage.delete(key: 'jwt_token');
      // - Navigaciju na Login ekran
    
    return handler.next(err);
  }
}
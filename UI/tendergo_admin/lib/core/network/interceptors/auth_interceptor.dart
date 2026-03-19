import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/network/constants/api_endpoints.dart'; // Importuj svoje rute

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // 1. Proveri da li je ruta login ili register - za njih nam ne treba Bearer token
    if (options.path == ApiEndpoints.login || options.path == ApiEndpoints.register) {
      return handler.next(options);
    }

    // 2. Čitanje tokena
    String? token = await _secureStorage.read(key: 'jwt_token');

    // 3. Dodavanje u header
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    return handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Ako backend vrati 401, to znači da je token istekao ili je nevažeći
    if (err.response?.statusCode == 401) {
      print("Token više nije validan. Korisnik treba biti odjavljen.");
      
      // OVDE MOŽEŠ DODATI:
      // - Brisanje tokena: _secureStorage.delete(key: 'jwt_token');
      // - Navigaciju na Login ekran
    }
    return handler.next(err);
  }
}
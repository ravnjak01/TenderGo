import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart' as dio_io;
import 'package:tendergo_admin/core/network/interceptors/auth_interceptor.dart';

class DioClient {

  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',defaultValue: 'http://localhost:5180/api/'
  );

  /// Server origin without the /api/ suffix, e.g. "http://localhost:5180".
  /// Used to resolve relative image paths returned by the backend.
  static String get baseOrigin {
    final uri = Uri.tryParse(_baseUrl);
    if (uri == null) return '';
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  /// Resolves a raw image path/URL from the backend into a full URL.
  /// Returns null when [raw] is null or empty.
  static String? resolveImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final origin = baseOrigin;
    if (origin.isEmpty) return trimmed;
    return trimmed.startsWith('/')
        ? '$origin$trimmed'
        : '$origin/$trimmed';
  }

  static Dio getDio() {
    String finalUrl = _baseUrl;
    if (!finalUrl.endsWith('/')) {
      finalUrl = '$finalUrl/';
    }
  
    final dio = Dio(
      BaseOptions(
        baseUrl: finalUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: 'application/json',
      ),
    );

   if (dio.httpClientAdapter is dio_io.IOHttpClientAdapter) {
      (dio.httpClientAdapter as dio_io.IOHttpClientAdapter).createHttpClient = () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          return host == '10.0.2.2' || host == 'localhost';
        };
        return client;
      };
    }

  
    dio.interceptors.add(AuthInterceptor());

    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    return dio;
  }
}
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart' as dio_io;
import 'package:flutter/foundation.dart';
import 'package:tendergo/shared/core/network/interceptors/auth_interceptor.dart';

class DioClient {
  // 1. Privatni konstruktor i statička instanca (Singleton)
  DioClient._internal();
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;

  static Dio? _dio;

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get _apiBaseUrl {
    if (_configuredApiBaseUrl.trim().isNotEmpty) {
      return _configuredApiBaseUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  static String get baseOrigin {
    final uri = Uri.tryParse(_apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return '';
    return uri.hasPort
        ? '${uri.scheme}://${uri.host}:${uri.port}'
        : '${uri.scheme}://${uri.host}';
  }

  static String get _baseUrl {
    final trimmed = _apiBaseUrl.trim();
    final withoutTrailingSlash = trimmed.replaceAll(RegExp(r'/+$'), '');

    if (withoutTrailingSlash.endsWith('/api')) {
      return '$withoutTrailingSlash/';
    }
    return '$withoutTrailingSlash/api/';
  }

  static String? resolveImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final trimmed = raw.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final origin = baseOrigin;
    if (origin.isEmpty) return trimmed;
    return trimmed.startsWith('/') ? '$origin$trimmed' : '$origin/$trimmed';
  }

  // 2. Vrati uvijek ISTU instancu
  static Dio getDio() {
    if (_dio != null) return _dio!;

    String finalUrl = _baseUrl;
    if (!finalUrl.endsWith('/')) {
      finalUrl = '$finalUrl/';
    }

    _dio = Dio(
      BaseOptions(
        baseUrl: finalUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
        // UKLONJEN 'application/json' odavde da ne kvari Multipart preglede!
      ),
    );

    if (_dio!.httpClientAdapter is dio_io.IOHttpClientAdapter) {
      (_dio!.httpClientAdapter as dio_io.IOHttpClientAdapter).createHttpClient =
          () {
            final client = HttpClient();
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) {
                  return host == '10.0.2.2' || host == 'localhost';
                };
            return client;
          };
    }

    _dio!.interceptors.add(AuthInterceptor(_dio!));

    if (kDebugMode) {
      _dio!.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: false,
          responseHeader: true,
          responseBody: false,
          error: true,
          logPrint: (obj) => debugPrint(obj.toString()),
        ),
      );
    }

    return _dio!;
  }
}
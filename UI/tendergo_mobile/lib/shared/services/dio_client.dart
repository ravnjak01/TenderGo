import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart' as dio_io;
import 'package:flutter/foundation.dart';
import 'package:tendergo/shared/core/network/interceptors/auth_interceptor.dart';

class DioClient {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:5000',
  );

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
        responseType: ResponseType.json,
        contentType: 'application/json',
      ),
    );

    if (dio.httpClientAdapter is dio_io.IOHttpClientAdapter) {
      (dio.httpClientAdapter as dio_io.IOHttpClientAdapter).createHttpClient =
          () {
            final client = HttpClient();
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) {
                  return host == '10.0.2.2' || host == 'localhost';
                };
            return client;
          };
    }

    dio.interceptors.add(AuthInterceptor(dio));

    if (kDebugMode) {
      dio.interceptors.add(
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

    return dio;
  }
}

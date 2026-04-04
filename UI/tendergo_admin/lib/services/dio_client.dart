import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart' as dio_io;
import 'package:tendergo_admin/core/network/interceptors/auth_interceptor.dart';

class DioClient {

  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',defaultValue: 'http://localhost:5179/api'
  );

  static Dio getDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
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

   // dio.interceptors.add(LogInterceptor(
     // requestHeader: true, 
     // requestBody: true, 
    //));

    return dio;
  }
}
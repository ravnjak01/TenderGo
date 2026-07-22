import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:tendergo/admin/routes/routes.dart';
import 'package:tendergo/shared/core/network/constants/api_endpoints.dart';

const _publicPaths = <String>[
  ApiEndpoints.login,
  ApiEndpoints.register,
  ApiEndpoints.forgotPassword,
  ApiEndpoints.resetPassword,
];

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final FlutterSecureStorage _storage;

  bool _isRefreshing = false;
  final List<Completer<Response<dynamic>>> _pendingQueue = [];

  AuthInterceptor(this._dio, [this._storage = const FlutterSecureStorage()]);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isPublicPath(options.path)) {
      return handler.next(options);
    }

    final token = await _storage.read(key: 'jwt_token');

    if (token != null && JwtDecoder.isExpired(token)) {
      final refreshed = await _tryRefresh();
      if (!refreshed) {
        await _clearSession();
        return handler.reject(
          DioException(
            requestOptions: options,
            error: 'Session expired. Please log in again.',
            type: DioExceptionType.cancel,
          ),
        );
      }
    }

    final freshToken = await _storage.read(key: 'jwt_token');

    if (freshToken != null &&
        freshToken.trim().isNotEmpty &&
        _looksLikeJwt(freshToken)) {
      options.headers['Authorization'] = 'Bearer $freshToken';
    } else {
      options.headers.remove('Authorization');
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (err.requestOptions.extra['isRetry'] == true) {
      return handler.next(err);
    }

    if (statusCode != 401 ||
        _isPublicPath(path) ||
        path == ApiEndpoints.refreshToken) {
      return handler.next(err);
    }

    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>>();
      _pendingQueue.add(completer);
      try {
        final response = await completer.future;
        return handler.resolve(response);
      } catch (_) {
        return handler.next(err);
      }
    }

    _isRefreshing = true;
    final refreshed = await _tryRefresh();

    if (!refreshed) {
      _isRefreshing = false;
      _rejectPending();
      await _clearSession();
      return handler.next(err);
    }

    _isRefreshing = false;

    try {
      final response = await _retry(err.requestOptions);
      _resolvePending(response);
      return handler.resolve(response);
    } on DioException catch (retryErr) {
      _rejectPending();
      return handler.next(retryErr);
    }
  }

  bool _isPublicPath(String path) => _publicPaths.contains(path);

  bool _looksLikeJwt(String token) => token.split('.').length == 3;

  Future<bool> _tryRefresh() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final plainDio = Dio(_dio.options);
      final response = await plainDio.post(
        ApiEndpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final envelope = response.data as Map<String, dynamic>?;
        final innerData = envelope?['data'] as Map<String, dynamic>?;

        final newAccessToken = innerData?['token']?.toString();
        final newRefreshToken = innerData?['refreshToken']?.toString();

        if (newAccessToken == null ||
            newAccessToken.isEmpty ||
            !_looksLikeJwt(newAccessToken)) {
          return false;
        }

        await _storage.write(key: 'jwt_token', value: newAccessToken);
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          await _storage.write(key: 'refresh_token', value: newRefreshToken);
        }
        return true;
      }

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retry(RequestOptions original) async {
    final token = await _storage.read(key: 'jwt_token');
    final headers = Map<String, dynamic>.from(original.headers);

    if (token != null && token.trim().isNotEmpty && _looksLikeJwt(token)) {
      headers['Authorization'] = 'Bearer $token';
    } else {
      headers.remove('Authorization');
    }

    dynamic finalData = original.data;

    if (original.data is FormData) {
      final originalFormData = original.data as FormData;
      final newFormData = FormData();

      newFormData.fields.addAll(originalFormData.fields);

      for (final filePair in originalFormData.files) {
        newFormData.files.add(
          MapEntry(
            filePair.key,
            filePair.value.clone(),
          ),
        );
      }
      finalData = newFormData;
      headers.remove('content-type');
    }

    return _dio.request<dynamic>(
      original.path,
      data: finalData,
      queryParameters: original.queryParameters,
      options: Options(
        method: original.method,
        headers: headers,
        extra: {'isRetry': true},
      ),
    );
  }

  void _resolvePending(Response<dynamic> response) {
    for (final c in _pendingQueue) {
      c.complete(response);
    }
    _pendingQueue.clear();
  }

  void _rejectPending() {
    for (final c in _pendingQueue) {
      c.completeError(Exception('Token refresh failed – session ended'));
    }
    _pendingQueue.clear();
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'refresh_token');

    AppRoutes.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
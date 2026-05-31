import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

abstract class BaseService<T> {
  final Dio _dio;
  final String _endpointPath;
  final T Function(Map<String, dynamic>) _fromJson;

  BaseService(this._dio, this._endpointPath, this._fromJson);

  @protected
  Dio get dio => _dio;

  @protected
  String get endpointPath => _endpointPath;

  @protected
  T parseJson(Map<String, dynamic> json) => _fromJson(json);

  Future<List<T>> getAll({
    int page = 1,
    int pageSize = 100,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final Map<String, dynamic> params = {
        'page': page,
        'pageSize': pageSize,
        ...?queryParameters,
      };

      final response = await _dio.get(_endpointPath, queryParameters: params);

      final List list = response.data['result'] as List;
      return list.map((x) => _fromJson(Map<String, dynamic>.from(x))).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error fetching data');
    }
  }

  Future<T> insert(dynamic requestData) async {
    try {
      final body = requestData is Map ? requestData : requestData.toJson();

      final response = await _dio.post(_endpointPath, data: body);
      final raw = response.data;

      final payload = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
                ? raw['data'] as Map<String, dynamic>
                : (raw['result'] is Map<String, dynamic>
                      ? raw['result'] as Map<String, dynamic>
                      : raw))
          : const <String, dynamic>{};

      return _fromJson(payload);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error creating entity');
    }
  }

  Future<bool> update(int id, dynamic requestData) async {
    try {
      final body = requestData is Map ? requestData : requestData.toJson();

      final response = await _dio.patch('$_endpointPath/$id', data: body);

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error updating entity');
    }
  }

  Future<String> delete(int id) async {
    try {
      final response = await _dio.delete('$_endpointPath/$id');

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['message']?.toString() ?? 'Delete successful.';
      }

      return 'Delete successful.';
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error deleting entity');
    }
  }
}

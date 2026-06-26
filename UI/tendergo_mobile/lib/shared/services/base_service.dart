import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tendergo/shared/services/response_parser.dart';

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

  @protected
  dynamic extractData(dynamic responseData) => ResponseParser.data(responseData);

  @protected
  List<dynamic> extractList(dynamic responseData) =>
      ResponseParser.list(responseData);

  @protected
  Map<String, dynamic> extractObject(dynamic responseData) =>
      ResponseParser.object(responseData);

  @protected
  String extractErrorMessage(DioException e, String fallback) =>
      ResponseParser.errorMessage(e, fallback);

  Future<List<T>> getAll({
    int page = 1,
    int pageSize = 100,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final params = {
        'page': page,
        'pageSize': pageSize,
        ...?queryParameters,
      };

      final response = await _dio.get(
        _endpointPath,
        queryParameters: params,
      );

      final listData = extractList(response.data);

      return listData
          .map((x) => _fromJson(Map<String, dynamic>.from(x as Map)))
          .toList();
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error fetching data'));
    }
  }

  Future<T> insert(dynamic requestData) async {
    try {
      final body = requestData is Map ? requestData : requestData.toJson();

      final response = await _dio.post(_endpointPath, data: body);
      return _fromJson(extractObject(response.data));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error creating entity'));
    }
  }

  Future<bool> update(int id, dynamic requestData) async {
    try {
      final body = requestData is Map ? requestData : requestData.toJson();

      final response = await _dio.patch('$_endpointPath/$id', data: body);

      final statusCode = response.statusCode ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error updating entity'));
    }
  }

  Future<String> delete(int id) async {
    try {
      await _dio.delete('$_endpointPath/$id');
      return 'Delete successful.';
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error deleting entity'));
    }
  }
}

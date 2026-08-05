import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/services/api_helper.dart';

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

  /// Sigurno izvlači podatak bez obzira da li backend koristi 'data' wrapper ili ne
  @protected
  dynamic extractData(dynamic responseData) {
    if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
      return responseData['data'];
    }
    return responseData;
  }

  @protected
  String extractErrorMessage(DioException e, String fallback) {
    return ApiHelper.handleDioError(e, fallbackMessage: fallback).message;
  }

  /// GET: api/endpoint (Sa paginacijom i filterima)
  Future<PagedResult<T>> get({
    int page = 1,
    int pageSize = 10,
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

      return PagedResult.fromJson(
        Map<String, dynamic>.from(response.data as Map),
        _fromJson,
      );
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri dohvaćanju podataka'));
    }
  }

  /// GET: api/endpoint/{id}
  Future<T> getById(int id) async {
    try {
      final response = await _dio.get('$_endpointPath/$id');
      final data = extractData(response.data);
      return _fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri dohvaćanju zapisa'));
    }
  }

  /// POST: api/endpoint
  Future<T> insert(dynamic requestData) async {
    try {
      final body = requestData is Map ? requestData : requestData.toJson();

      final response = await _dio.post(_endpointPath, data: body);
      final data = extractData(response.data);
      return _fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri kreiranju zapisa'));
    }
  }

  /// PUT: api/endpoint/{id}
  Future<T> update(int id, dynamic requestData) async {
    try {
      final body = requestData is Map ? requestData : requestData.toJson();

      // Izmijenjeno iz .patch u .put (u skladu sa BaseController u .NET-u)
      final response = await _dio.put('$_endpointPath/$id', data: body);
      final data = extractData(response.data);
      
      return _fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri ažuriranju zapisa'));
    }
  }

  /// DELETE: api/endpoint/{id}
  Future<String> delete(int id) async {
    try {
      final response = await _dio.delete('$_endpointPath/$id');
      
      // Ako backend vrati JSON { "message": "Location deleted..." }
      if (response.data is Map && response.data.containsKey('message')) {
        return response.data['message'].toString();
      }
      
      return 'Zapis uspješno obrisan.';
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri brisanju zapisa'));
    }
  }
}
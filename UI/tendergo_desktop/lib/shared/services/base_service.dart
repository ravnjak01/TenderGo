import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/services/api_helper.dart';

abstract class BaseService<TDto,TInsertRequest,TUpdateRequest> {
  final Dio _dio;
  final String _endpointPath;
  final TDto Function(Map<String, dynamic>) _fromJson;

  BaseService(this._dio, this._endpointPath, this._fromJson);

  @protected
  Dio get dio => _dio;

  @protected
  String get endpointPath => _endpointPath;

  @protected
  TDto parseJson(Map<String, dynamic> json) => _fromJson(json);

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

  /// GET: api/endpoint 
  Future<PagedResult<TDto>> get({
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

      final payload = extractData(response.data);

      if (payload is! Map) {
        throw Exception('Neispravan format odgovora za paginaciju.');
      }

      return PagedResult.fromJson(
        Map<String, dynamic>.from(payload),
        _fromJson,
      );
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri dohvaćanju podataka'));
    }
  }

  /// GET: api/endpoint/{id}
  Future<TDto> getById(int id) async {
    try {
      final response = await _dio.get('$_endpointPath/$id');
      final data = extractData(response.data);
      return _fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri dohvaćanju zapisa'));
    }
  }

  /// POST: api/endpoint
  Future<TDto> insert(TInsertRequest requestData) async {
    try {
      final body = requestData is Map 
        ? requestData 
        : (requestData as dynamic).toJson();

      final response = await _dio.post(_endpointPath, data: body);
      final data = extractData(response.data);
      return _fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri kreiranju zapisa'));
    }
  }

  /// PUT: api/endpoint/{id}
  Future<TDto> update(int id, TUpdateRequest requestData) async {
    try {
    final body = requestData is Map 
        ? requestData 
        : (requestData as dynamic).toJson();
      final response = await _dio.patch('$_endpointPath/$id', data: body);
      final data = extractData(response.data);
      
      if (data == null) {
        return getById(id);
      }
      
      return _fromJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri ažuriranju zapisa'));
    }
  }

  /// DELETE: api/endpoint/{id}
  Future<String> delete(int id) async {
    try {
      final response = await _dio.delete('$_endpointPath/$id');
      
      if (response.data is Map && response.data.containsKey('message')) {
        return response.data['message'].toString();
      }
      
      return 'Zapis uspješno obrisan.';
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri brisanju zapisa'));
    }
  }
}
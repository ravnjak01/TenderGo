import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';

class TenderService {
  final Dio _dio;

  TenderService(this._dio);



  
  Future<List<TenderDto>> getAll({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getAll,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      final List<dynamic> data = response.data['result'] ?? [];

      return data
          .map((x) => TenderDto.fromJson(x as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching tenders');
    }
  }

  Future<TenderDto> getById(int id) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getById(id));

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching tender');
    }
  }

 



  Future<TenderDto> cancel(int id) async {
    try {
      final response = await _dio.patch(TenderApiEndpoints.cancel(id));

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error canceling tender');
    }
  }


  Future<List<TenderDto>> search(TenderSearchRequest request) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.search(request.searchTerm ?? ''),
      );

      final List<dynamic> data = response.data['result'] ?? [];

      return data
          .map((x) => TenderDto.fromJson(x as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error searching tenders');
    }
  }

 

 
}

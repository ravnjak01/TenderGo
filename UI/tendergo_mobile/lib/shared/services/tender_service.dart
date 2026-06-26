import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_insert_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/services/image_service.dart';
import 'package:tendergo/shared/services/response_parser.dart';

class TenderService {
  final Dio _dio;
  final ImageService _imageService;

  TenderService(this._dio, this._imageService);

  ImageService get imageService => _imageService;

  // Pomoćna metoda za pretvaranje fajlova u bajtove
  Future<TenderInsertRequest> _withImageBytes(
    TenderInsertRequest data,
    List<PlatformFile>? imageFiles,
  ) async {
    if (imageFiles == null || imageFiles.isEmpty) return data;

    final byteImages = <Uint8List>[];
    for (final file in imageFiles) {
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        byteImages.add(file.bytes!);
        continue;
      }
      if (file.path != null && file.path!.isNotEmpty) {
        final diskBytes = await File(file.path!).readAsBytes();
        if (diskBytes.isNotEmpty) byteImages.add(diskBytes);
      }
    }

    if (byteImages.isEmpty) return data;

    return TenderInsertRequest(
      title: data.title,
      maxBudget: data.maxBudget,
      locationId: data.locationId,
      description: data.description,
      categoryId: data.categoryId,
      deadline: data.deadline,
      imageBytes: byteImages,
    );
  }

  // Koristi zajednički šablon za bezbjedno izvlačenje podataka iz koverte
  T _unwrapEnvelope<T>(Response response, T Function(dynamic data) mapper) {
    return mapper(ResponseParser.data(response.data));
  }

  // Centralizovano čitanje grešaka iz ApiErrorEnvelope
  Exception _handleError(DioException e, String defaultMessage) {
    return Exception(ResponseParser.errorMessage(e, defaultMessage));
  }

  // ==================== API METODE ====================

  Future<List<TenderDto>> getAll({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getAll,
        queryParameters: {'page': page, 'pageSize': pageSize},
      );

      return ResponseParser.dtoList(response.data, TenderDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju tendera');
    }
  }

  Future<TenderDto> getById(int id) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getById(id));
      return _unwrapEnvelope(response, (data) => TenderDto.fromJson(data as Map<String, dynamic>));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju detalja tendera');
    }
  }

  Future<List<TenderDto>> getActive() async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getActive);

      return ResponseParser.dtoList(response.data, TenderDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju aktivnih tendera');
    }
  }

  Future<TenderDto> create(
    TenderInsertRequest data, {
    List<PlatformFile>? imageFiles,
  }) async {
    try {
      final request = await _withImageBytes(data, imageFiles);
      final response = await _dio.post(
        TenderApiEndpoints.insert,
        data: request.toJson(),
      );

      return _unwrapEnvelope(response, (data) => TenderDto.fromJson(data as Map<String, dynamic>));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri kreiranju tendera');
    }
  }

  Future<TenderDto> award(TenderDto tender, int bidId) async {
    try {
      final response = await _dio.patch(TenderApiEndpoints.award(tender, bidId));
      return _unwrapEnvelope(response, (data) => TenderDto.fromJson(data as Map<String, dynamic>));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri dodjeljivanju tendera');
    }
  }

  Future<TenderDto> cancel(int id) async {
    try {
      final response = await _dio.patch(TenderApiEndpoints.cancel(id));
      return _unwrapEnvelope(response, (data) => TenderDto.fromJson(data as Map<String, dynamic>));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri otkazivanju tendera');
    }
  }

  Future<List<dynamic>> getByCategory(int id) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getByCategory(id));
      return List<dynamic>.from(ResponseParser.list(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju kategorije');
    }
  }

  Future<List<dynamic>> getByUser(String userId) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getByUser(userId));
      return List<dynamic>.from(ResponseParser.list(response.data));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        return const [];
      }
      throw _handleError(e, 'Greška pri dohvaćanju korisničkih tendera');
    }
  }

  Future<List<TenderDto>> search(TenderSearchRequest request) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.search(request.searchTerm ?? ''),
      );

      return ResponseParser.dtoList(response.data, TenderDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri pretrazi tendera');
    }
  }

  Future<List<dynamic>> allowedActions(int id) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.allowedActions(id));
      return List<dynamic>.from(ResponseParser.list(response.data));
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju dozvoljenih akcija');
    }
  }

  Future<bool> toggleBookmark(int tenderId) async {
    try {
      final response = await _dio.post(TenderApiEndpoints.toggleBookmark(tenderId));
      final data = ResponseParser.data(response.data);
      return data is bool ? data : false;
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri izmjeni bookmark-a');
    }
  }

  Future<List<TenderDto>> getBookmarked() async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getBookmarks);

      return ResponseParser.dtoList(response.data, TenderDto.fromJson);
    } on DioException catch (e) {
      throw _handleError(e, 'Greška pri učitavanju bookmark-ovanih tendera');
    }
  }
}

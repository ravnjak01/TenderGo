import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_insert_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/services/image_service.dart';

class TenderService {
  final Dio _dio;
  final ImageService _imageService;
  static const _storage = FlutterSecureStorage();

  TenderService(this._dio, this._imageService);

  ImageService get imageService => _imageService;

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<TenderInsertRequest> _withImageBytes(
    TenderInsertRequest data,
    List<PlatformFile>? imageFiles,
  ) async {
    if (imageFiles == null || imageFiles.isEmpty) {
      return data;
    }

    final byteImages = <Uint8List>[];
    for (final file in imageFiles) {
      if (file.bytes != null && file.bytes!.isNotEmpty) {
      // 2. file.bytes je već Uint8List, nema potrebe za .toList()
      byteImages.add(file.bytes!); 
      continue;
    }

      if (file.path != null && file.path!.isNotEmpty) {
        final diskBytes = await File(file.path!).readAsBytes();
        if (diskBytes.isNotEmpty) {
          byteImages.add(diskBytes);
        }
      }
    }

    if (byteImages.isEmpty) {
      return data;
    }

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

  // ===== GET ALL =====
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

// ===== GET ALL LOCATIONS =====
 


  // ===== GET BY ID =====
  Future<TenderDto> getById(int id) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getById(id),
      );

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching tender');
    }
  }

  // ===== ACTIVE =====
  Future<List<TenderDto>> getActive() async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getActive,
      );

      final data = response.data;
      if (data is! List) {
        throw Exception('Unexpected active tenders response format');
      }

      final tenders = <TenderDto>[];
      for (final item in data) {
        if (item is! Map<String, dynamic>) continue;
        try {
          tenders.add(TenderDto.fromJson(item));
        } catch (e, stack) {
          debugPrint('Skipping malformed active tender: $e\n$stack');
        }
      }
      return tenders;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching active tenders');
    }
  }

  // ===== CLOSED =====
  Future<List<TenderDto>> getClosed() async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getClosed,
      );

      return List<TenderDto>.from(
        response.data.map((x) => TenderDto.fromJson(x)),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching closed tenders');
    }
  }

 

   Future<List<TenderDto>> getCancelled() async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getCancelled,
      );

      return List<TenderDto>.from(
        response.data.map((x) => TenderDto.fromJson(x)),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching cancelled tenders');
    }
  }

  // ===== CREATE =====
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

      //zadnje popravio payload za response data ,zasto je potrebno ovo sve ispitat
      final payload = response.data is Map<String, dynamic>
          ? (response.data['data'] is Map<String, dynamic> 
              ? response.data['data'] as Map<String, dynamic> 
              : (response.data['result'] is Map<String, dynamic> ? response.data['result'] as Map<String, dynamic> : response.data))
          : const <String, dynamic>{};

      return TenderDto.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error creating tender');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
 

  // ===== UPDATE =====
  Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        TenderApiEndpoints.update(id),
        data: data,
      );

      return response.statusCode! >= 200 && response.statusCode! < 300;
    } on DioException catch (e) {
      return false;
    }
  }

  // ===== DELETE =====
  Future<bool> delete(int id) async {
    try {
      final response = await _dio.delete(
        TenderApiEndpoints.delete(id),
      );

      return response.statusCode! >= 200 && response.statusCode! < 300;
    } on DioException catch (e) {
      return false;
    }
  }

 

  // ===== AWARD =====
  Future<TenderDto> award(TenderDto tender, int bidId) async {
    try {
      final response = await _dio.patch(
        TenderApiEndpoints.award(tender, bidId),
      );

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error awarding tender');
    }
  }

  // ===== CANCEL =====
  Future<TenderDto> cancel(int id) async {
    try {
      final response = await _dio.patch(
        TenderApiEndpoints.cancel(id),
      );

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error canceling tender');
    }
  }

  // ===== BY CATEGORY =====
  Future<List<dynamic>> getByCategory(int id) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getByCategory(id),
      );

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching by category');
    }
  }

  // ===== BY USER =====
  Future<List<dynamic>> getByUser(String userId) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getByUser(userId),
      );

      final payload = response.data;
      if (payload is List) {
        return List<dynamic>.from(payload);
      }
      if (payload is Map<String, dynamic>) {
        final listLike = payload['result'] ?? payload['items'] ?? payload['data'];
        if (listLike is List) {
          return List<dynamic>.from(listLike);
        }
      }
      return const [];
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        return const [];
      }
      throw Exception(e.response?.data ?? 'Error fetching user tenders');
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

  // ===== ALLOWED ACTIONS =====
  Future<List<dynamic>> allowedActions(int id) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.allowedActions(id),
      );

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching actions');
    }
  }
}

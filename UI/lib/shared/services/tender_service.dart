import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/dto/tender_post_dto.dart';
import 'package:tendergo/shared/services/image_service.dart';

class TenderService {
  final Dio _dio;
  final ImageService _imageService;
  static const _storage = FlutterSecureStorage();

  TenderService(this._dio, this._imageService);

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

    final byteImages = <List<int>>[];
    for (final file in imageFiles) {
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        byteImages.add(file.bytes!.toList());
        continue;
      }

      if (file.path != null && file.path!.isNotEmpty) {
        final diskBytes = await File(file.path!).readAsBytes();
        if (diskBytes.isNotEmpty) {
          byteImages.add(diskBytes.toList());
        }
      }
    }

    if (byteImages.isEmpty) {
      return data;
    }

    return TenderInsertRequest(
      title: data.title,
      maxBudget: data.maxBudget,
      locationName: data.locationName,
      description: data.description,
      categoryId: data.categoryId,
      deadline: data.deadline,
      imageBytes: byteImages,
    );
  }


  Future<Options> _options() async {
    final token = await _getToken();

    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
  }

  // ===== GET ALL =====
  Future<List<TenderDto>> getAll({int page = 1, int pageSize = 10}) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getAll,
        queryParameters: {'page': page, 'pageSize': pageSize},
        options: await _options(),
      );

      final List<dynamic> data = response.data['result'] ?? [];

      return data
          .map((x) => TenderDto.fromJson(x as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching tenders');
    }
  }

  // ===== GET BY ID =====
  Future<TenderDto> getById(int id) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getById(id),
        options: await _options(),
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
        options: await _options(),
      );

      return List<TenderDto>.from(
        response.data.map((x) => TenderDto.fromJson(x)),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching active tenders');
    }
  }

  // ===== CLOSED =====
  Future<List<TenderDto>> getClosed() async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getClosed,
        options: await _options(),
      );

      return List<TenderDto>.from(
        response.data.map((x) => TenderDto.fromJson(x)),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching closed tenders');
    }
  }

  // ===== DRAFTS =====
  Future<List<TenderDto>> getDrafts() async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getDrafts,
        options: await _options(),
      );

      return List<TenderDto>.from(
        response.data.map((x) => TenderDto.fromJson(x)),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching draft tenders');
    }
  }

   Future<List<TenderDto>> getCancelled() async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getCancelled,
        options: await _options(),
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
        options: await _options(),
      );

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error creating tender');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  // ===== CREATE DRAFT =====
  Future<TenderDto> createDraft(
    TenderInsertRequest data, {
    List<PlatformFile>? imageFiles,
  }) async {
    try {
      final request = await _withImageBytes(data, imageFiles);

      final response = await _dio.post(
        TenderApiEndpoints.insertDraft,
        data: request.toJson(),
        options: await _options(),
      );

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error creating draft tender');
    }
  }

  // ===== UPDATE =====
  Future<bool> update(int id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch(
        TenderApiEndpoints.update(id),
        data: data,
        options: await _options(),
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
        options: await _options(),
      );

      return response.statusCode! >= 200 && response.statusCode! < 300;
    } on DioException catch (e) {
      return false;
    }
  }

  // ===== ACTIVATE =====
  Future<dynamic> activate(int id) async {
    try {
      final response = await _dio.put(
        TenderApiEndpoints.activate(id),
        options: await _options(),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error activating tender');
    }
  }

  // ===== AWARD =====
  Future<TenderDto> award(TenderDto tender, int bidId) async {
    try {
      final response = await _dio.patch(
        TenderApiEndpoints.award(tender, bidId),
        options: await _options(),
      );

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error awarding tender');
    }
  }

  // ===== CANCEL =====
  Future<dynamic> cancel(int id) async {
    try {
      final response = await _dio.patch(
        TenderApiEndpoints.cancel(id),
        options: await _options(),
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error canceling tender');
    }
  }

  // ===== BY CATEGORY =====
  Future<List<dynamic>> getByCategory(int id) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.getByCategory(id),
        options: await _options(),
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
        options: await _options(),
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

  // ===== ALLOWED ACTIONS =====
  Future<List<dynamic>> allowedActions(int id) async {
    try {
      final response = await _dio.get(
        TenderApiEndpoints.allowedActions(id),
        options: await _options(),
      );

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching actions');
    }
  }
}

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo_admin/models/dto/tender_dto.dart';
import 'package:tendergo_admin/models/dto/tender_post_dto.dart';
import 'package:tendergo_admin/services/image_service.dart';

class TenderService {
  final Dio _dio;
  final ImageService _imageService;
  static const _storage = FlutterSecureStorage();

  TenderService(this._dio, this._imageService);

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  //NE RADI PRIKAZIVANJE SLIKA U TENDER_DETAILS_SCREEN, PROVJERITI KASNIJE

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
      final response = await _dio.post(
        TenderApiEndpoints.insert,
        data: data.toJson(),
        options: await _options(),
      );
      final created = TenderDto.fromJson(response.data);
      if (imageFiles != null && imageFiles.isNotEmpty) {
        await _imageService.uploadAllForTender(created.id!, imageFiles);
      }
      return created;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error creating tender');
    }
  }

  // ===== CREATE DRAFT =====
  Future<TenderDto> createDraft(
    TenderInsertRequest data, {
    List<PlatformFile>? imageFiles,
  }) async {
    try {
      final response = await _dio.post(
        TenderApiEndpoints.insertDraft,
        data: data.toJson(),
        options: await _options(),
      );
      final created = TenderDto.fromJson(response.data);
      if (imageFiles != null && imageFiles.isNotEmpty) {
        await _imageService.uploadAllForTender(created.id!, imageFiles);
      }
      return created;
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

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
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

import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_insert_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/services/image_service.dart';

class TenderService {
  final Dio _dio;
  final ImageService _imageService;

  TenderService(this._dio, this._imageService);

  ImageService get imageService => _imageService;

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

  Future<List<TenderDto>> getActive() async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getActive);

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

  Future<List<TenderDto>> getClosed() async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getClosed);

      return List<TenderDto>.from(
        response.data.map((x) => TenderDto.fromJson(x)),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching closed tenders');
    }
  }

  Future<List<TenderDto>> getCancelled() async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getCancelled);

      return List<TenderDto>.from(
        response.data.map((x) => TenderDto.fromJson(x)),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching cancelled tenders');
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

      final payload = response.data is Map<String, dynamic>
          ? (response.data['data'] is Map<String, dynamic>
                ? response.data['data'] as Map<String, dynamic>
                : (response.data['result'] is Map<String, dynamic>
                      ? response.data['result'] as Map<String, dynamic>
                      : response.data))
          : const <String, dynamic>{};

      return TenderDto.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error creating tender');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

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

  Future<TenderDto> cancel(int id) async {
    try {
      final response = await _dio.patch(TenderApiEndpoints.cancel(id));

      return TenderDto.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error canceling tender');
    }
  }

  Future<List<dynamic>> getByCategory(int id) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getByCategory(id));

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching by category');
    }
  }

  Future<List<dynamic>> getByUser(String userId) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getByUser(userId));

      final payload = response.data;
      if (payload is List) {
        return List<dynamic>.from(payload);
      }
      if (payload is Map<String, dynamic>) {
        final listLike =
            payload['result'] ?? payload['items'] ?? payload['data'];
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

  Future<List<dynamic>> allowedActions(int id) async {
    try {
      final response = await _dio.get(TenderApiEndpoints.allowedActions(id));

      return List<dynamic>.from(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching actions');
    }
  }

  Future<bool> toggleBookmark(int tenderId) async {
    try {
      final response = await _dio.post(
        TenderApiEndpoints.toggleBookmark(tenderId),
      );

      if (response.data is Map<String, dynamic>) {
        return response.data['isBookmarked'] as bool? ?? false;
      }
      return false;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error toggling bookmark');
    }
  }

  Future<List<TenderDto>> getBookmarked() async {
    try {
      final response = await _dio.get(TenderApiEndpoints.getBookmarks);

      final payload = response.data;
      List<dynamic> rawList = [];

      if (payload is List) {
        rawList = payload;
      } else if (payload is Map<String, dynamic>) {
        rawList =
            payload['result'] ?? payload['data'] ?? payload['items'] ?? [];
      }

      return rawList
          .whereType<Map<String, dynamic>>()
          .map((x) => TenderDto.fromJson(x))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching bookmarked tenders');
    }
  }
}

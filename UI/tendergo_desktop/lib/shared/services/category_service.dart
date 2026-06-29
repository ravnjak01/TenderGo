import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/category_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/requests/category_insert_request.dart';
import 'package:tendergo/shared/models/requests/category_search_request.dart';
import 'package:tendergo/shared/models/requests/category_update_request.dart';
import 'package:tendergo/shared/services/base_service.dart';
import 'package:flutter/foundation.dart';
class CategoryService extends BaseService<CategoryDto> {
  CategoryService(Dio dio)
      : super(dio, CategoryApiEndpoints.baseUrl, CategoryDto.fromJson);


  Future<CategoryDto> insertCategory(CategoryInsertRequest request) {
    return insert(request);
  }

  Future<bool> updateCategory(int id, CategoryUpdateRequest request) async {
    try {
      final response = await dio.patch(
        CategoryApiEndpoints.update(id),
        data: request.toJson(),
      );

      final statusCode = response.statusCode ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Error updating category'));
    }
  }

  Future<CategoryDto> activateCategory(int id) async {
    try {
      final response = await dio.patch(CategoryApiEndpoints.activate(id));
      final envelope = response.data;

      if (envelope is! Map<String, dynamic>) {
        throw Exception('Invalid response format.');
      }

      final data = envelope['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response format: data is not an object.');
      }

      return parseJson(data);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Error activating category'));
    }
  }

  Future<CategoryDto> deactivateCategory(int id) async {
    try {
      final response = await dio.patch(CategoryApiEndpoints.deactivate(id));
      final envelope = response.data;

      if (envelope is! Map<String, dynamic>) {
        throw Exception('Invalid response format.');
      }

      final data = envelope['data'];

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response format: data is not an object.');
      }

      return parseJson(data);
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Error deactivating category'));
    }
  }


  Future<List<CategoryDto>> search(CategorySearchRequest request) async {
    try {
      final response = await dio.get(
        CategoryApiEndpoints.search(
          request.searchTerm ?? '',
          page: request.page,
          pageSize: request.pageSize,
        ),
      );
      debugPrint('CATEGORY SEARCH RESPONSE: ${response.data}');

      final envelope = response.data;
      final data=envelope['data'];
      final result=data['result'];
      if (envelope is! Map<String, dynamic>) {
        throw Exception('Invalid response format.');
      }

      if (result is! List) {
        throw Exception('Invalid response format: result is not a list.');
      }

      return result
          .map((x) => CategoryDto.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList();
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Error searching categories'));
    }
  }

  Future<List<CategoryStatisticsDto>> getCategoryStatistics() async {
    try {
      final response = await dio.get(CategoryApiEndpoints.categoryStatistics);
      final envelope = response.data;

      if (envelope is! Map<String, dynamic>) {
        throw Exception('Invalid response format.');
      }

      final data = envelope['data'];

      if (data is! List) {
        throw Exception('Invalid response format: data is not a list.');
      }

      return data
          .map(
            (x) => CategoryStatisticsDto.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Error fetching category statistics'),
      );
    }
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is List && errors.isNotEmpty) {
        return errors.join('\n');
      }

      final message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return fallback;
  }
}

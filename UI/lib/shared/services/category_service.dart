import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo/shared/core/network/constants/category_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';

class CategoryService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  CategoryService(this._dio);

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Options> _options() async {
    final token = await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Options(headers: headers);
  }

  Future<List<CategoryDto>> getAll() async {
    try {
      final response = await _dio.get(
        CategoryApiEndpoints.getAll,
        queryParameters: {'page': 1, 'pageSize': 100},
        options: await _options(),
      );

      final List list = response.data['result'] as List;
      return list
          .map((x) => CategoryDto.fromJson(Map<String, dynamic>.from(x)))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching categories');
    }
  }

  Future<CategoryDto> insert(CategoryDto data) async {
    try {
      final response = await _dio.post(
        CategoryApiEndpoints.insert,
        data: {'name': data.name},
        options: await _options(),
      );

      final raw = response.data;
      final payload = raw is Map<String, dynamic>
          ? (raw['result'] is Map<String, dynamic>
                ? raw['result'] as Map<String, dynamic>
                : raw)
          : const <String, dynamic>{};

      return CategoryDto.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error creating category');
    }
  }

  Future<bool> delete(int id) async {
    try {
      final response = await _dio.delete(
        CategoryApiEndpoints.delete(id),
        options: await _options(),
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error deleting category');
    }
  }

  Future<bool> update(int id, CategoryDto data) async {
    try {
      final response = await _dio.patch(
        CategoryApiEndpoints.update(id),
        data: {'name': data.name},
        options: await _options(),
      );

      return response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300;
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error updating category');
    }
  }
}

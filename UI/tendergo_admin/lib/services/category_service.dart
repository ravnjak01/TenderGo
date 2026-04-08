import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tendergo_admin/core/network/constants/category_api_endpoints.dart';
import 'package:tendergo_admin/models/dto/category_dto.dart';

class CategoryService {
  final Dio _dio;
  static const _storage = FlutterSecureStorage();

  CategoryService(this._dio);

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Options> _options() async {
    final token = await _getToken();
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return Options(
      headers: headers,
    );
  }

  Future<List<CategoryDto>> getAll() async {
    try {
      final response = await _dio.get(
        CategoryApiEndpoints.getAll,
        queryParameters: {
          'page': 1,
          'pageSize': 100,
        },
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
        data: data.toJson(),
        options: await _options(),
      );

      return CategoryDto.fromJson(response.data);
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
}
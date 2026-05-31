import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/category_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/services/base_service.dart';

class CategoryService extends BaseService<CategoryDto> {


  CategoryService(Dio dio) : super(dio, CategoryApiEndpoints.baseUrl, CategoryDto.fromJson);

  Future<CategoryDto> activateCategory(int id) async {
    try {
      final response = await dio.patch(CategoryApiEndpoints.activate(id));
      final raw = response.data;
      final payload = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
              ? raw['data'] as Map<String, dynamic>
              : raw)
          : const <String, dynamic>{};

      return parseJson(payload);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Error activating category');
    }
  }
}

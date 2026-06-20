import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/category_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/requests/category_search_request.dart';
import 'package:tendergo/shared/services/base_service.dart';

class CategoryService extends BaseService<CategoryDto> {
  CategoryService(Dio dio)
    : super(dio, CategoryApiEndpoints.baseUrl, CategoryDto.fromJson);

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
      throw Exception(
        e.response?.data?['message'] ?? 'Error activating category',
      );
    }
  }

  
Future<List<CategoryDto>> search(CategorySearchRequest request) async {
    try {
      final response = await dio.get(
        CategoryApiEndpoints.search(
          request.searchTerm ?? '', 
          page: request.page, 
          pageSize: request.pageSize
        ),
      );

      final rawData = response.data;
      List<dynamic> dataList = [];

      // Provjera strukture: PagedResult obično ima 'result', 'results' ili 'data' unutar sebe
      if (rawData is Map<String, dynamic>) {
        if (rawData['result'] != null) {
          dataList = rawData['result'] as List;
        } else if (rawData['Result'] != null) {
          dataList = rawData['Result'] as List;
        } else if (rawData['data'] is Map && rawData['data']['result'] != null) {
          dataList = rawData['data']['result'] as List;
        } else if (rawData['data'] is List) {
          dataList = rawData['data'] as List;
        }
      } else if (rawData is List) {
        dataList = rawData;
      }

      return dataList
          .map((x) => CategoryDto.fromJson(x as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? e.response?.data ?? 'Error searching categories'
      );
    }
  }

  Future<CategoryStatisticsDto> getCategoryStatistics() async {
    try {
      final response = await dio.get(CategoryApiEndpoints.categoryStatistics);
      final raw = response.data;
      final payload = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
                ? raw['data'] as Map<String, dynamic>
                : raw)
          : const <String, dynamic>{};

      return CategoryStatisticsDto.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Error fetching category statistics',
      );
    }
  }

}

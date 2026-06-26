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
      return parseJson(extractObject(response.data));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error activating category'));
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
      final data = extractList(response.data);

      return data
          .map((x) => CategoryDto.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList();
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error searching categories'));
    }
  }

  Future<List<CategoryStatisticsDto>> getCategoryStatistics() async {
    try {
      final response = await dio.get(CategoryApiEndpoints.categoryStatistics);
      final data = extractList(response.data);

      return data
          .map(
            (x) => CategoryStatisticsDto.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Error fetching category statistics'),
      );
    }
  }
}

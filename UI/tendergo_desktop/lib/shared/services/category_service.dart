import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/category_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/requests/category_search_request.dart';
import 'package:tendergo/shared/models/requests/category_update_request.dart';
import 'package:tendergo/shared/services/base_service.dart';

class CategoryService extends BaseService<CategoryDto> {
  CategoryService(Dio dio)
      : super(dio, CategoryApiEndpoints.baseUrl, CategoryDto.fromJson);

  // Napomena: insert(), getById() i delete() su već naslijeđeni iz BaseService-a!

  /// GET: api/category (Paginacija i pretraga preko CategorySearchRequest)
  Future<PagedResult<CategoryDto>> getCategories(CategorySearchRequest request) {
    return get(
      page: request.page ?? 1,
      pageSize: request.pageSize ?? 10,
      queryParameters: request.toJson(),
    );
  }

  /// PATCH: api/category/{id} (Ažuriranje kategorije - vraća ažurirani CategoryDto)
  @override
  Future<CategoryDto> update(int id, dynamic requestData) async {
    try {
      final body = requestData is Map ? requestData : requestData.toJson();
      final response = await dio.patch(
        CategoryApiEndpoints.update(id),
        data: body,
      );

      final data = extractData(response.data);
      return parseJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri ažuriranju kategorije'));
    }
  }

  Future<CategoryDto> updateCategory(int id, CategoryUpdateRequest request) {
    return update(id, request);
  }

  /// PATCH: api/category/{id}/activate
  Future<CategoryDto> activateCategory(int id) async {
    try {
      final response = await dio.patch(CategoryApiEndpoints.activate(id));
      final data = extractData(response.data);
      return parseJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri aktivaciji kategorije'));
    }
  }

  /// PATCH: api/category/{id}/deactivate
  Future<CategoryDto> deactivateCategory(int id) async {
    try {
      final response = await dio.patch(CategoryApiEndpoints.deactivate(id));
      final data = extractData(response.data);
      return parseJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Greška pri deaktivaciji kategorije'));
    }
  }

  /// GET: api/category/statistics
  Future<List<CategoryStatisticsDto>> getCategoryStatistics() async {
    try {
      final response = await dio.get(CategoryApiEndpoints.statistics);
      final data = extractData(response.data);

      if (data is List) {
        return data
            .map((x) => CategoryStatisticsDto.fromJson(
                  Map<String, dynamic>.from(x as Map),
                ))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Greška pri dohvaćanju statistike kategorija'),
      );
    }
  }
}
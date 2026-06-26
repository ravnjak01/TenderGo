import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/services/base_service.dart';

class TenderService extends BaseService<TenderDto> {
  TenderService(Dio dio)
      : super(dio, TenderApiEndpoints.getAll, TenderDto.fromJson);

  @override
  Future<List<TenderDto>> getAll({
    int page = 1,
    int pageSize = 10,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get(
        TenderApiEndpoints.getAll,
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
          ...?queryParameters,
        },
      );

      final data = extractList(response.data);

      return data
          .map((x) => TenderDto.fromJson(x as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error fetching tenders'));
    }
  }

  Future<TenderDto> getById(int id) async {
    try {
      final response = await dio.get(TenderApiEndpoints.getById(id));

      return TenderDto.fromJson(extractObject(response.data));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error fetching tender'));
    }
  }

  Future<TenderDto> cancel(int id) async {
    try {
      final response = await dio.patch(TenderApiEndpoints.cancel(id));

      return TenderDto.fromJson(extractObject(response.data));
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error canceling tender'));
    }
  }

  Future<List<TenderDto>> search(TenderSearchRequest request) async {
    try {
      final response = await dio.get(
        TenderApiEndpoints.search(request.searchTerm ?? ''),
      );

      final data = extractList(response.data);

      return data
          .map((x) => TenderDto.fromJson(x as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error searching tenders'));
    }
  }
}

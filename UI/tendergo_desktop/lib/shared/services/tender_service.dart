import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/tender_api_endpoints.dart';
import 'package:tendergo/shared/models/dto/admin_tender_dto.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/admin_tender_search_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/services/base_service.dart';

class TenderService extends BaseService<TenderDto> {
  TenderService(Dio dio)
      : super(dio, TenderApiEndpoints.getAll, TenderDto.fromJson);

  Future<PagedResult<AdminTenderDto>> getAdminTenders(AdminTenderSearchRequest request) async {
  try {
    final response = await dio.get(
      'admin/tenders',
      queryParameters: request.toJson(), // Šalje ispravne Page i PageSize parametre
    );

    final envelope = response.data as Map<String, dynamic>;
    final pagedData = envelope['data'] as Map<String, dynamic>;


    return PagedResult<AdminTenderDto>.fromJson(
      pagedData,
      (json) => AdminTenderDto.fromJson(json as Map<String, dynamic>),
    );
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
Future<PagedResult<AdminTenderDto>> search(AdminTenderSearchRequest request) async {
  try {
    final response = await dio.get(
      'admin/tenders/search', 
      queryParameters: request.toJson(), 
    );

    final envelope = response.data as Map<String, dynamic>;

    final pagedData = envelope['data'] as Map<String, dynamic>;

    return PagedResult<AdminTenderDto>.fromJson(
      pagedData,
      (json) => AdminTenderDto.fromJson(json as Map<String, dynamic>),
    );
    
  } on DioException catch (e) {
    throw Exception(extractErrorMessage(e, 'Error searching tenders'));
  }
}
}

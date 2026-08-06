import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/tender_endpoints.dart';
import 'package:tendergo/shared/models/dto/admin_tender_dto.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/requests/tender_cancel_request.dart';
import 'package:tendergo/shared/models/requests/tender_search_request.dart';
import 'package:tendergo/shared/services/base_service.dart';

class TenderService extends BaseService<TenderDto> {
  TenderService(Dio dio)
      : super(
          dio,
          TenderApiEndpoints.baseUrl, // Bazna ruta npr. 'tender'
          TenderDto.fromJson,
        );

  // Napomena: insert(), update(), delete() i getById() su već naslijeđeni iz BaseService-a!

  /// GET: api/tender (Standardna paginirana pretraga tendera za korisnike)
  Future<PagedResult<TenderDto>> getTendersPaged(TenderSearchRequest request) {
    return get(
      page: request.page ?? 1,
      pageSize: request.pageSize ?? 10,
      queryParameters: request.toJson(),
    );
  }

  /// GET: api/tender/admin (Specifična pretraga tendera za Admin panel sa AdminTenderDto)
  Future<PagedResult<AdminTenderDto>> searchAdminTenders(
    TenderSearchRequest request,
  ) async {
    try {
      final response = await dio.get(
        TenderApiEndpoints.adminSearch,
        queryParameters: request.toJson(),
      );

      final data = extractData(response.data);

      return PagedResult<AdminTenderDto>.fromJson(
        Map<String, dynamic>.from(data as Map),
        (json) => AdminTenderDto.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Greška pri dohvaćanju admin tendera'),
      );
    }
  }

  /// PATCH: api/tender/{id}/cancel (Otkaži tender sa obrazloženjem)
  Future<TenderDto> cancel(int id, TenderCancelRequest request) async {
    try {
      final response = await dio.patch(
        TenderApiEndpoints.cancel(id),
        data: request.toJson(),
      );

      final data = extractData(response.data);
      return parseJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Greška pri otkazivanju tendera'),
      );
    }
  }
}
import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/location_endpoints.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/dto/paged_result.dart';
import 'package:tendergo/shared/models/requests/location_filter_request.dart';
import 'package:tendergo/shared/models/requests/location_insert_request.dart';
import 'package:tendergo/shared/models/requests/location_search_request.dart';
import 'package:tendergo/shared/models/requests/location_update_request.dart';
import 'package:tendergo/shared/services/base_service.dart';

class LocationService extends BaseService<LocationDto,LocationInsertRequest,LocationUpdateRequest> {
  LocationService(Dio dio)
      : super(dio, LocationEndpoints.baseUrl, LocationDto.fromJson);


  /// GET: api/location 
  Future<PagedResult<LocationDto>> getLocationsPaged(
    LocationSearchRequest request,
  ) {
    return get(
      page: request.page ?? 1,
      pageSize: request.pageSize ?? 10,
      queryParameters: request.toJson(),
    );
  }

  /// GET: api/location/all 
  Future<List<LocationDto>> getAllForDropdown({
    LocationFilterRequest? filter,
    bool includeInactive = false,
  }) async {
    try {
      final queryParameters = filter?.toQueryParams() ?? {};
      if (includeInactive) {
        queryParameters['includeInactive'] = true;
      }

      final response = await dio.get(
        LocationEndpoints.getAllFlat, 
        queryParameters: queryParameters,
      );

      final data = extractData(response.data);

      if (data is List) {
        return data
            .map((x) => parseJson(Map<String, dynamic>.from(x as Map)))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Greška pri dohvaćanju svih lokacija'),
      );
    }
  }

  /// PATCH: api/location/{id}/activate
  Future<LocationDto> activateLocation(int id) async {
    try {
      final response = await dio.patch(LocationEndpoints.activate(id));
      final data = extractData(response.data);
      return parseJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Greška pri aktivaciji lokacije'),
      );
    }
  }

  /// PATCH: api/location/{id}/deactivate
  Future<LocationDto> deactivateLocation(int id) async {
    try {
      final response = await dio.patch(LocationEndpoints.deactivate(id));
      final data = extractData(response.data);
      return parseJson(Map<String, dynamic>.from(data as Map));
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Greška pri deaktivaciji lokacije'),
      );
    }
  }

  /// GET: api/location/statistics
  Future<List<LocationStatsDto>> getLocationStatistics() async {
    try {
      final response = await dio.get(LocationEndpoints.statistics);
      final data = extractData(response.data);

      if (data is List) {
        return data
            .map(
              (x) => LocationStatsDto.fromJson(
                Map<String, dynamic>.from(x as Map),
              ),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Greška pri dohvaćanju statistike lokacija'),
      );
    }
  }

  /// GET: api/location/overview
  Future<LocationOverviewDto> getLocationOverview() async {
    try {
      final response = await dio.get(LocationEndpoints.overview);
      final data = extractData(response.data);

      return LocationOverviewDto.fromJson(
        Map<String, dynamic>.from(data as Map),
      );
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Greška pri dohvaćanju pregleda lokacija'),
      );
    }
  }
}
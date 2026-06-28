import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/location_endpoints.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/requests/location_filter_request.dart';
import 'package:tendergo/shared/models/requests/location_insert_request.dart';
import 'package:tendergo/shared/models/requests/location_search_request.dart';
import 'package:tendergo/shared/models/requests/location_update_request.dart';
import 'package:tendergo/shared/services/base_service.dart';

class LocationService extends BaseService<LocationDto> {
  LocationService(Dio dio)
      : super(dio, LocationEndpoints.baseUrl, LocationDto.fromJson);

  Future<List<LocationDto>> getLocations(
    LocationFilterRequest filter, {
    bool includeInactive = false,
  }) async {
    try {
      final queryParameters = filter.toQueryParams();
      if (includeInactive) {
        queryParameters['includeInactive'] = true;
      }

      final response = await dio.get(
        LocationEndpoints.getAll,
        queryParameters: queryParameters,
      );

      final data = extractList(response.data);

      return data
          .map((x) => parseJson(Map<String, dynamic>.from(x as Map)))
          .toList();
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error fetching locations'));
    }
  }

  Future<LocationDto> insertLocation(LocationInsertRequest request) {
    return insert(request);
  }

  Future<bool> updateLocation(int id, LocationUpdateRequest request) {
    return update(id, request);
  }

  Future<String> deleteLocation(int id) => delete(id);

  Future<LocationDto> activateLocation(int id) async {
    try {
      final response = await dio.patch(LocationEndpoints.activate(id));
      return _parseSingleLocation(response.data);
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error activating location'));
    }
  }

  Future<LocationDto> deactivateLocation(int id) async {
    try {
      final response = await dio.patch(LocationEndpoints.deactivate(id));
      return _parseSingleLocation(response.data);
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error deactivating location'));
    }
  }

  Future<List<LocationDto>> search(LocationSearchRequest request) async {
    try {
      final response = await dio.get(
        LocationEndpoints.search(
          searchTerm: request.searchTerm,
          isActive: request.isActive,
          page: request.page,
          pageSize: request.pageSize,
        ),
      );

      final data = extractList(response.data);

      return data
          .map((x) => LocationDto.fromJson(Map<String, dynamic>.from(x as Map)))
          .toList();
    } on DioException catch (e) {
      throw Exception(extractErrorMessage(e, 'Error searching locations'));
    }
  }

  Future<List<LocationStatsDto>> getLocationStatistics() async {
    try {
      final response = await dio.get(LocationEndpoints.locationStatistics);

      final data = extractList(response.data);

      return data
          .map(
            (x) => LocationStatsDto.fromJson(
              Map<String, dynamic>.from(x as Map),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Error fetching location statistics'),
      );
    }
  }

  Future<LocationOverviewDto> getLocationOverview() async {
    try {
      final response = await dio.get(LocationEndpoints.locationOverview);

      return LocationOverviewDto.fromJson(extractObject(response.data));
    } on DioException catch (e) {
      throw Exception(
        extractErrorMessage(e, 'Error fetching location overview'),
      );
    }
  }

  LocationDto _parseSingleLocation(dynamic envelope) {
    return parseJson(extractObject(envelope));
  }
}

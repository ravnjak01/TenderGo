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

      final List<dynamic> data = response.data;
      return data.map((x) => parseJson(x as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error fetching locations');
    }
  }

  static List<String> distinctCountries(List<LocationDto> locations) {
    final countries = locations.map((l) => l.country).toSet().toList();
    countries.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return countries;
  }

  static List<String> distinctRegions(List<LocationDto> locations) {
    final regions = locations
        .map((l) => l.region)
        .where((r) => r != null && r.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    regions.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return regions;
  }

  Future<LocationDto> insertLocation(LocationInsertRequest request) {
    return insert(
      LocationDto(
        id: 0,
        name: request.name,
        country: request.country,
        region: request.region,
      ),
    );
  }

  Future<bool> updateLocation(int id, LocationUpdateRequest request) {
    return update(
      id,
      LocationDto(
        id: id,
        name: request.name ?? '',
        country: request.country ?? '',
        region: request.region,
      ),
    );
  }

  Future<String> deleteLocation(int id) => delete(id);

  Future<LocationDto> activateLocation(int id) async {
    try {
      final response = await dio.patch(LocationEndpoints.activate(id));
      final raw = response.data;
      final payload = raw is Map<String, dynamic>
          ? (raw['data'] is Map<String, dynamic>
                ? raw['data'] as Map<String, dynamic>
                : raw)
          : const <String, dynamic>{};

      return parseJson(payload);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Error activating location',
      );
    }
  }
    Future<List<LocationDto>> search(LocationSearchRequest request) async {
    try {
      final response = await dio.get(
        LocationEndpoints.search(request.searchTerm ?? '', page: request.page, pageSize: request.pageSize  ),
      );

      final List<dynamic> data = response.data['result'] ?? [];

      return data
          .map((x) => LocationDto.fromJson(x as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? 'Error searching locations');
    }
  }

}

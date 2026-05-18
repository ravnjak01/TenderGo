import 'package:dio/dio.dart';
import 'package:tendergo/shared/core/network/constants/location_endpoints.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/requests/location_filter_request.dart';
import 'package:tendergo/shared/services/base_service.dart';

class LocationService extends BaseService<LocationDto> {
  LocationService(Dio dio)
      : super(dio, LocationEndpoints.baseUrl, LocationDto.fromJson);

  Future<List<LocationDto>> getLocations(LocationFilterRequest filter) async {
    try {
   
      final response = await dio.get(
        LocationEndpoints.getAll,
        queryParameters:filter.toQueryParams() ,
      );

      final List<dynamic> data = response.data;
      return data
          .map((x) => parseJson(x as Map<String, dynamic>))
          .toList();
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

  Future<LocationDto> insertLocation({
    required String name,
    required String country,
    String? region,
  }) {
    return insert(LocationDto(
      id: 0,
      name: name,
      country: country,
      region: region,
    ));
  }

  Future<bool> updateLocation(
    int id, {
    required String name,
    required String country,
    String? region,
  }) {
    return update(id, LocationDto(
      id: id,
      name: name,
      country: country,
      region: region,
    ));
  }

  Future<bool> deleteLocation(int id) => delete(id);
}

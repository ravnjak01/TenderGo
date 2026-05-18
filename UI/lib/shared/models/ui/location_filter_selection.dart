import 'package:tendergo/shared/models/dto/location_dto.dart';

class LocationFilterSelection {
  final String country;
  final String? region;
  final int? locationId;
  final String? cityName;

  const LocationFilterSelection({
    required this.country,
    this.region,
    this.locationId,
    this.cityName,
  });

  bool get isCountryOnly => region == null && locationId == null;

  bool get isRegionOnly => region != null && locationId == null;

  String get displayLabel {
    if (locationId != null && cityName != null && cityName!.isNotEmpty) {
      if (region != null && region!.isNotEmpty) {
        return '$cityName, $region ($country)';
      }
      return '$cityName ($country)';
    }
    if (region != null && region!.isNotEmpty) {
      return '$region ($country)';
    }
    return country;
  }

  factory LocationFilterSelection.countryOnly(String country) =>
      LocationFilterSelection(country: country);

  factory LocationFilterSelection.region({
    required String country,
    required String region,
  }) =>
      LocationFilterSelection(country: country, region: region);

  factory LocationFilterSelection.city(LocationDto location) =>
      LocationFilterSelection(
        country: location.country,
        region: location.region,
        locationId: location.id,
        cityName: location.name,
      );
}

import 'package:tendergo/shared/core/utils/json_parser.dart';

class LocationDto {
  final int id;
  final String name;
  final String country;
  final String? region;
  final bool isActive;

  LocationDto({
    required this.id,
    required this.name,
    required this.country,
    this.region,
    this.isActive = true,
  });

  String get displayLabel {
    if (region != null && region!.isNotEmpty) {
      return '$name, $region ($country)';
    }
    return '$name ($country)';
  }

  factory LocationDto.fromJson(Map<String, dynamic> json) {
    return LocationDto(
      id: JsonParser.readInt(json['id']),
      name: JsonParser.readString(json['name'], fallback: 'Unknown'),
      country: JsonParser.readString(json['country'], fallback: 'Unknown'),
      region: json['region'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      if (region != null) 'region': region,
      'isActive': isActive,
    };
  }
}

class LocationStatsDto {
  final String locationName;
  final int tenderCount;
  final int locationId;
  final bool isActive;
  

  LocationStatsDto({
    required this.locationName,
    required this.tenderCount,
    required this.locationId,
    required this.isActive,
  });

  factory LocationStatsDto.fromJson(Map<String, dynamic> json) {
    return LocationStatsDto(
      locationName: json['locationName'] as String? ?? 'Unknown',
      tenderCount: json['tenderCount'] as int? ?? 0,
      locationId: json['locationId'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}

class LocationOverviewDto {
  final int totalLocations;
  final int activeLocations;
  final int inactiveLocations;
  final int locationWithActiveTenders;

  LocationOverviewDto({
    required this.totalLocations,
    required this.activeLocations,
    required this.inactiveLocations,
    required this.locationWithActiveTenders,
  });

  factory LocationOverviewDto.fromJson(Map<String, dynamic> json) {
    return LocationOverviewDto(
      totalLocations: json['totalLocations'] as int? ?? 0,
      activeLocations: json['activeLocations'] as int? ?? 0,
      inactiveLocations: json['inactiveLocations'] as int? ?? 0,
      locationWithActiveTenders: json['locationWithActiveTenders'] as int? ?? 0,
    );
  }
}
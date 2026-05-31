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

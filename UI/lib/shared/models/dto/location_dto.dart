class LocationDto {
  final int id;
  final String name;
  final String country;
  final String? region;

  LocationDto({
    required this.id,
    required this.name,
    required this.country,
    this.region,
  });

  String get displayLabel {
    if (region != null && region!.isNotEmpty) {
      return '$name, $region ($country)';
    }
    return '$name ($country)';
  }

  factory LocationDto.fromJson(Map<String, dynamic> json) {
    return LocationDto(
      id: json['id'] as int,
      name: json['name'] as String,
      country: json['country'] as String,
      region: json['region'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      if (region != null) 'region': region,
    };
  }
}

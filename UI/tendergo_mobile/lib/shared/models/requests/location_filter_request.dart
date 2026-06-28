
class LocationFilterRequest {
  final String? country;
  final String? region;

  const LocationFilterRequest({
    this.country,
    this.region,
  });

  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {};
    if (country != null && country!.isNotEmpty) params['country'] = country;
    if (region != null && region!.isNotEmpty) params['region'] = region;
    return params;
  }
}
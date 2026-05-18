class LocationInsertRequest {

  final String country;
  final String city;
  final String region;

  const LocationInsertRequest({
    required this.country,
    required this.city,
    required this.region,
  });

  Map<String, dynamic> toJson() => {
        'city': city, 
        'country': country,
        'region': region,
      };
}
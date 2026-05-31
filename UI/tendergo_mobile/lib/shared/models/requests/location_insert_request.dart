class LocationInsertRequest {

  final String country;
  final String name;
  final String? region;

  const LocationInsertRequest({
    required this.country,
    required this.name,
    this.region,
  });

  Map<String, dynamic> toJson() => {
        'name': name, 
        'country': country,
        'region': region,
      };
}
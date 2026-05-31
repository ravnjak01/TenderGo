  class LocationUpdateRequest {

    final String? name;
    final String? country;
    final String? region;

    const LocationUpdateRequest({
      this.name,
      this.country,
      this.region,
    });

    Map<String, dynamic> toJson() => {
          'name': name, 
          'country': country,
          'region': region,
        };
  }
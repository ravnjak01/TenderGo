class UpdateAddressDto {
  final String? street;
  final String? city;
  final String? postalCode;
  final String? country;

  UpdateAddressDto({
    this.street,
    this.city,
    this.postalCode,
    this.country,
  });

  Map<String, dynamic> toJson() {
    return {
      if (street != null) 'street': street,
      if (city != null) 'city': city,
      if (postalCode != null) 'postalCode': postalCode,
      if (country != null) 'country': country,
    };
  }
}

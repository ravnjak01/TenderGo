



class AddressDto {
  final int id;
  final String? country;
  final String? city;
  final String? street;
  final String? postalCode;

  AddressDto({
    required this.id,
    this.country,
    this.city,
    this.street,
    this.postalCode,
  });

  factory AddressDto.fromJson(Map<String, dynamic> json) {
    
    return AddressDto(
      id: json['id'] as int? ?? 0,
      country: json['country'] as String? ?? '',
      city: json['city'] as String? ?? '',
      street: json['street'] as String? ?? '',
      postalCode: json['postalCode'] as String? ?? json['postal_code'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'city': city,
      'street': street,
      'postalCode': postalCode,
    };
  }
}

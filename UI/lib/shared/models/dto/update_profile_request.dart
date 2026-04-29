import 'dart:convert';

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

class UpdateProfileRequest {
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final UpdateAddressDto? address;
  final List<int>? imageBytes; 

  UpdateProfileRequest({
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.address,
    this.imageBytes,
  });

  Map<String, dynamic> toJson() {
    return {
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address!.toJson(),
      if (imageBytes != null) 'imageBytes': base64Encode(imageBytes!),
    };
  }
}
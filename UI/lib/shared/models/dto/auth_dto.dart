class ResetPasswordRequest {
  final String email;
  final String token;
  final String newPassword;

  ResetPasswordRequest({
    required this.email,
    required this.token,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() {
    return {'email': email, 'token': token, 'newPassword': newPassword};
  }
}


class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() {
    return {'email': email, 'password': password};
  }
}

class RegisterRequest {
  final String email;
  final String password;
  final String firstName;
  final String lastName;

  RegisterRequest({
    required this.email,
    required this.password,
    required this.firstName,
    required this.lastName,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
    };
  }
}

class AddressDto {
  final int id;
  final String country;
  final String city;
  final String street;
  final String postalCode;

  AddressDto({
    required this.id,
    required this.country,
    required this.city,
    required this.street,
    required this.postalCode,
  });

  // Koristi se kada primaš podatke sa API-ja
  factory AddressDto.fromJson(Map<String, dynamic> json) {
    return AddressDto(
      id: json['id'] ?? 0,
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      postalCode: json['postalCode'] ?? '',
    );
  }

  // Koristi se kada šalješ podatke na API
  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'city': city,
      'street': street,
      'postalCode': postalCode,
    };
  }
}





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
    String _pickString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        final normalized = value.toString().trim();
        if (normalized.isNotEmpty) {
          return normalized;
        }
      }
      return '';
    }

    int _pickInt(List<String> keys) {
      final value = _pickString(keys);
      if (value.isEmpty) return 0;
      return int.tryParse(value) ?? 0;
    }

    return AddressDto(
      id: _pickInt(['id', 'addressId', 'address_id', 'Id']),
      country: _pickString(['country', 'Country', 'addressCountry']),
      city: _pickString(['city', 'City', 'addressCity']),
      street: _pickString(['street', 'Street', 'addressStreet']),
      postalCode: _pickString([
        'postalCode',
        'postal_code',
        'PostalCode',
        'zipCode',
        'zip_code',
      ]),
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

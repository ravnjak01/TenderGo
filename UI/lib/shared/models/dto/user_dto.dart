import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/services/dio_client.dart';

class UserDto {
  final String? id;
  final String email;
  final String username;
  final AddressDto? address;
  final String? profileImageUrl;
  final List<String> roles;
  final String firstName;
  final String lastName;
  UserDto({
    this.id,
    required this.email,
    required this.username,
    this.address,
    this.profileImageUrl,
    required this.roles,
    required this.firstName,
    required this.lastName,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];
    final rawAddress =
        json['address'] ??
        json['Address'] ??
        json['userAddress'] ??
        json['user_address'] ??
        json['AddressDto'];

    final rawProfileImage =
        json['profileImageUrl'] ??
        json['imageUrl'] ??
        json['avatarUrl'] ??
        json['profilePicture'] ??
        json['photoUrl'] ??
        json['profileImage'] ??
        json['avatar'] ??
        json['image'];

    final hasFlatAddressFields =
        json['street'] != null ||
        json['Street'] != null ||
        json['addressStreet'] != null ||
        json['city'] != null ||
        json['City'] != null ||
        json['addressCity'] != null ||
        json['postalCode'] != null ||
        json['postal_code'] != null ||
        json['PostalCode'] != null ||
        json['zipCode'] != null ||
        json['zip_code'] != null ||
        json['country'] != null ||
        json['Country'] != null ||
        json['addressCountry'] != null;

    AddressDto? parsedAddress;
    if (rawAddress is Map<String, dynamic>) {
      parsedAddress = AddressDto.fromJson(rawAddress);
    } else if (rawAddress is Map) {
      parsedAddress = AddressDto.fromJson(
        rawAddress.map((key, value) => MapEntry(key.toString(), value)),
      );
    } else if (hasFlatAddressFields) {
      parsedAddress = AddressDto.fromJson({
        'id': json['addressId'] ?? json['address_id'] ?? json['id'] ?? 0,
        'street': json['street'] ?? json['addressStreet'] ?? '',
        'city': json['city'] ?? json['addressCity'] ?? '',
        'postalCode':
            json['postalCode'] ??
            json['postal_code'] ??
            json['zipCode'] ??
            json['zip_code'] ??
            '',
        'country': json['country'] ?? json['addressCountry'] ?? '',
      });
    }

    return UserDto(
      id: (json['id'] ?? json['userId'])?.toString(),
      email: json['email'] ?? '',
      username: (json['username'] ?? json['userName'] ?? '').toString(),
      address: parsedAddress,
      profileImageUrl: DioClient.resolveImageUrl(
        (rawProfileImage is Map<String, dynamic>
            ? (rawProfileImage['imageUrl'] ??
                      rawProfileImage['url'] ??
                      rawProfileImage['path'])
                  ?.toString()
            : rawProfileImage is Map
            ? (rawProfileImage['imageUrl'] ??
                      rawProfileImage['url'] ??
                      rawProfileImage['path'])
                  ?.toString()
            : rawProfileImage?.toString()),
      ),
      roles: rawRoles is List
          ? rawRoles
                .map((role) {
                  if (role is String) {
                    return role;
                  }

                  if (role is Map<String, dynamic>) {
                    return (role['name'] ??
                            role['roleName'] ??
                            role['value'] ??
                            '')
                        .toString();
                  }

                  if (role is Map) {
                    return (role['name'] ??
                            role['roleName'] ??
                            role['value'] ??
                            '')
                        .toString();
                  }

                  return role.toString();
                })
                .where((role) => role.trim().isNotEmpty)
                .toList()
          : [],
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'address': address?.toJson(),
      'profileImageUrl': profileImageUrl,
      'roles': roles,
      'firstName': firstName,
      'lastName': lastName,
    };
  }

  // metoda za dobijanje inicijala korisnika
  static String getInitials(UserDto user) {
    String initials = "";
    if (user.firstName.isNotEmpty) initials += user.firstName[0];
    if (user.lastName.isNotEmpty) initials += user.lastName[0];
    if (initials.isNotEmpty) return initials.toUpperCase();
    if (user.username.isNotEmpty) return user.username[0].toUpperCase();
    return '?';
  }
}

class UserPublicDto {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? location;
  final String? profileImageUrl;

  final double rating;
  final int reviewCount;

  final int tenderCount;
  final int bidsCount;

  UserPublicDto({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.location,
    required this.rating,
    required this.reviewCount,
    required this.tenderCount,
    required this.bidsCount,
    this.profileImageUrl,
  });

  factory UserPublicDto.fromJson(Map<String, dynamic> json) {
    return UserPublicDto(
      id: (json['id'] ?? '').toString(),
      username: (json['userName'] ?? json['username'] ?? '').toString(),
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      location: json['location'],
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      tenderCount: json['tenderCount'] ?? 0,
      bidsCount: json['bidsCount'] ?? 0,
      profileImageUrl: DioClient.resolveImageUrl(
        (json['profileImageUrl'] ??
                json['imageUrl'] ??
                json['avatarUrl'] ??
                json['profilePicture'] ??
                json['photoUrl'])
            ?.toString(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'location': location,
      'rating': rating,
      'reviewCount': reviewCount,
      'tenderCount': tenderCount,
      'bidsCount': bidsCount,
      'profileImageUrl': profileImageUrl,
    };
  }

  // helper metoda za inicijale
  static String getInitials(UserPublicDto user) {
    String initials = "";

    if (user.firstName.isNotEmpty) initials += user.firstName[0];
    if (user.lastName.isNotEmpty) initials += user.lastName[0];

    return initials.isEmpty
        ? user.username.isNotEmpty
              ? user.username[0].toUpperCase()
              : ''
        : initials.toUpperCase();
  }

  String get fullName => "$firstName $lastName";
}

class RateUserRequest {
  final String tenderId;
  final String ratedUserId;
  final String ratedByUserId;
  final int score;
  final String? comment;

  RateUserRequest({
    required this.tenderId,
    required this.ratedUserId,
    required this.ratedByUserId,
    required this.score,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
    'tenderId': tenderId,
    'ratedUserId': ratedUserId,
    'ratedByUserId': ratedByUserId,
    'score': score,
    if (comment != null) 'comment': comment,
  };
}

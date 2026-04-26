import 'package:tendergo/shared/models/dto/auth_dto.dart';

class UserDto {
  final String? id;
  final String email;
  final String username;
  final AddressDto? address;
  final List<String> roles;
  final String firstName;
  final String lastName;
  UserDto({
    this.id,
    required this.email,
    required this.username,
    this.address,
    required this.roles,
    required this.firstName,
    required this.lastName,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final rawRoles = json['roles'];

    return UserDto(
      id: (json['id'] ?? json['userId'])?.toString(),
      email: json['email'] ?? '',
      username: (json['username'] ?? json['userName'] ?? '').toString(),
      address: json['address'] != null
          ? AddressDto.fromJson(json['address'])
          : null,
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
    return initials.isEmpty
        ? user.username[0].toUpperCase()
        : initials.toUpperCase();
  }
}

class UserPublicDto {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? location;

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
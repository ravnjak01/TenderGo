import 'package:tendergo/shared/models/dto/address_dto.dart';
import 'package:tendergo/shared/models/has_initials.dart';
import 'package:tendergo/shared/services/dio_client.dart';


class UserDto implements HasInitials {
  final String id;
  final String email;
  final String? profileImageUrl;
  final AddressDto? address; 
  final List<String> roles;
  final bool isBanned;
  @override
  final String username;
  @override
  final String firstName;
  @override
  final String lastName;

  const UserDto({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
     this.address,
    this.profileImageUrl,
    required this.roles,
    required this.isBanned,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    var rawRoles = json['roles'] as List?;
    List<String> parsedRoles = rawRoles != null 
        ? List<String>.from(rawRoles.map((r) => r.toString())) 
        : const [];

    return UserDto(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profileImageUrl: DioClient.resolveImageUrl(json['profileImageUrl'] as String? ?? ''),
        address: json['address'] != null                          
          ? AddressDto.fromJson(json['address'] as Map<String, dynamic>)
          : null,
      roles: parsedRoles,
      isBanned: json['isBanned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'profileImageUrl': profileImageUrl,
        'address': address?.toJson(),
        'roles': roles,
        'isBanned': isBanned,
      };

}



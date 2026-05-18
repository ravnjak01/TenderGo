import 'package:tendergo/shared/core/utils/extensions/user_helper.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/services/dio_client.dart';


class UserDto {
  final String id;
  final String email;
  final String username;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  final AddressDto address; 
  final List<String> roles;

  const UserDto({
    required this.id,
    required this.email,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.address,
    this.profileImageUrl,
    required this.roles,
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
      address: AddressDto.fromJson(json['address'] as Map<String, dynamic>),
      roles: parsedRoles,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'profileImageUrl': profileImageUrl,
        'address': address.toJson(),
        'roles': roles,
      };

String get initials => UserHelper.generateInitials(
      firstName: firstName,
      lastName: lastName,
      username: username,
    );
}



import 'package:tendergo/shared/core/utils/extensions/user_helper.dart';
import 'package:tendergo/shared/services/dio_client.dart';

class UserPublicDto {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String location;
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
    required this.location,
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
      profileImageUrl: DioClient.resolveImageUrl(json['profileImageUrl'] as String? ?? ''),
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

   String get initials => UserHelper.generateInitials(
        firstName: firstName,
        lastName: lastName,
        username: username,
      );
  String get fullName => "$firstName $lastName";
}

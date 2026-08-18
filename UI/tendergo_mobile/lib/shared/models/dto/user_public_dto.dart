import 'package:tendergo/shared/models/has_initials.dart';
import 'package:tendergo/shared/services/dio_client.dart';

class UserPublicDto implements HasInitials {
  final String id;
  @override
  final String userName;
  @override
  final String firstName;
  @override
  final String lastName;
  final String location;
  final String? profileImageUrl;

  final double rating;
  final int reviewCount;

  final int tenderCount;
  final int bidsCount;

  UserPublicDto({
    required this.id,
    required this.userName,
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
      userName: (json['userName'] ?? '').toString(),
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      tenderCount: json['tenderCount'] as int? ?? 0,
      bidsCount: json['bidsCount'] as int? ?? 0,
      profileImageUrl: DioClient.resolveImageUrl(
        json['profileImageUrl'] as String?,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName, 
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
}
import 'package:tendergo/shared/core/utils/json_parser.dart';
import 'package:tendergo/shared/models/dto/admin_tender_dto.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/dto/tender_image_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';

class TenderDto extends AdminTenderDto {
  final String? description;
  final String createdByUserId;
  final int totalBids;
  final List<TenderImageDto> images;
  final LocationDto? location;
  final int categoryId;
  final String categoryName;
  final DateTime postedAt;

  const TenderDto({
    required super.id,
    required super.title,
    required super.createdByUserFullname,
    required super.deadline,
    required super.maxBudget,
    required super.status,
    this.description,
    required this.createdByUserId,
    required this.totalBids,
    required this.images,
    this.location,
    required this.categoryId,
    required this.categoryName,
    required this.postedAt,
  });

  TenderImageDto? get primaryImage {
    if (images.isEmpty) return null;
    return images.firstWhere(
      (img) => img.isPrimary && img.imageUrl.trim().isNotEmpty,
      orElse: () => images.firstWhere(
        (img) => img.imageUrl.trim().isNotEmpty,
        orElse: () => images.first,
      ),
    );
  }

  factory TenderDto.fromJson(Map<String, dynamic> json) {
    final adminDto = AdminTenderDto.fromJson(json);

    return TenderDto(
      id: adminDto.id,
      title: adminDto.title,
      createdByUserFullname: adminDto.createdByUserFullname,
      deadline: adminDto.deadline,
      maxBudget: adminDto.maxBudget,
      status: adminDto.status,
      description: JsonParser.readNullableString(json['description']),
      createdByUserId: JsonParser.readString(json['createdByUserId']),
      totalBids: JsonParser.readInt(json['totalBids']),
      images: _parseImages(json['images']),
      location: json['location'] != null && json['location'] is Map<String, dynamic>
          ? LocationDto.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      categoryId: JsonParser.readInt(json['categoryId']),
      categoryName: JsonParser.readString(json['categoryName'], fallback: 'No category'),
      postedAt: JsonParser.readDateTime(json['postedAt']),
    );
  }

  static List<TenderImageDto> _parseImages(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<Map<String, dynamic>>()
          .map(TenderImageDto.fromJson)
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      return [TenderImageDto.fromJson(raw)];
    }
    return const [];
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      'description': description,
      'createdByUserId': createdByUserId,
      'totalBids': totalBids,
      'images': images.map((img) => img.toJson()).toList(),
      'location': location?.toJson(),
      'categoryId': categoryId,
      'categoryName': categoryName,
      'postedAt': postedAt.toIso8601String(),
    });
    return map;
  }
}
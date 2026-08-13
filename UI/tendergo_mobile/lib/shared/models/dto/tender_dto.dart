import 'package:tendergo/shared/core/utils/json_parser.dart';
import 'package:tendergo/shared/models/dto/location_dto.dart';
import 'package:tendergo/shared/models/dto/tender_image_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/models/ui/tendercardmodel.dart';
import 'package:tendergo/shared/services/dio_client.dart';

class TenderDto {
  final int id;
  final String title;
  final String? description;
  final double maxBudget;
  final DateTime deadline;
  final String createdByUserId;
  final String createdByUserFullName;
  final TenderStatus status;
  final int totalBids;
  final List<TenderImageDto> images;
  final LocationDto location;
  final int categoryId;
  final String categoryName;
  final DateTime postedAt;

  const TenderDto({
    required this.id,
    required this.title,
    this.description,
    required this.maxBudget,
    required this.deadline,
    required this.createdByUserId,
    required this.createdByUserFullName,
    required this.status,
    required this.totalBids,
    required this.images,
    required this.location,
    required this.categoryId,
    required this.categoryName,
    required this.postedAt,
  });



  TenderImageDto? get primaryImage {
    if (images.isEmpty) return null;
    return images.firstWhere(
      (img) => img.isPrimary && img.imageUrl.trim().isNotEmpty,
      orElse: () => images.firstWhere((img) => img.imageUrl.trim().isNotEmpty, orElse: () => images.first),
    );
  }

  factory TenderDto.fromJson(Map<String, dynamic> json) {

    return TenderDto(
      id: JsonParser.readInt(json['id']),
      title: JsonParser.readString(json['title']),
      description: JsonParser.readNullableString(json['description']),
      maxBudget: JsonParser.readDouble(json['maxBudget']),
      deadline: JsonParser.readDateTime(json['deadline']),
      createdByUserId: JsonParser.readString(json['createdByUserId']),
      createdByUserFullName: JsonParser.readString(json['createdByUserFullName'], fallback: 'Unknown'),
      status: TenderStatus.fromValue(json['status']),
      totalBids: JsonParser.readInt(json['totalBids']),
      images: _parseImages(json['images']),
      location: _parseLocation(json['location']),
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'maxBudget': maxBudget,
        'deadline': deadline.toIso8601String(),
        'createdByUserId': createdByUserId,
        'createdByUserFullName': createdByUserFullName,
        'status': status.value, 
        'totalBids': totalBids,
        'images': images.map((img) => img.toJson()).toList(),
        'location': location.toJson(),
        'categoryId': categoryId,
        'categoryName': categoryName,
        'postedAt': postedAt.toIso8601String(),
      };

  TenderCardModel toCardModel() {
    return TenderCardModel(
      id: id,
      title: title,
      category: categoryName,
      status: status, 
      valueKM: maxBudget,
      deadline: deadline,
      postedAt: postedAt,
      tags: [location.name, location.country],
      imageUrl: DioClient.resolveImageUrl(primaryImage?.imageUrl),
      locationName: location.displayLabel,
    );
  }

  static LocationDto _parseLocation(dynamic value) {
    if (value == null) {
      return LocationDto(id: 0, name: 'Unknown', country: 'Unknown');
    }
    if (value is Map<String, dynamic>) {
      return LocationDto.fromJson(value);
    }
    return LocationDto(id: 0, name: 'Unknown', country: 'Unknown');
  }
}


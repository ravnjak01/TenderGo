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
  final String createdByFullname;
  final TenderStatus status;
  final int totalBids;
  final List<TenderImageDto> images;
  final LocationDto location;
  final int categoryId;
  final String categoryName;
  final DateTime postedAt;
  final String? profileImageUrl;

  const TenderDto({
    required this.id,
    required this.title,
    this.description,
    required this.maxBudget,
    required this.deadline,
    required this.createdByUserId,
    required this.createdByFullname,
    required this.status,
    required this.totalBids,
    required this.images,
    required this.location,
    required this.categoryId,
    required this.categoryName,
    required this.postedAt,
    this.profileImageUrl,
  });



  TenderImageDto? get primaryImage {
    if (images.isEmpty) return null;
    return images.firstWhere(
      (img) => img.isPrimary && img.imageUrl.trim().isNotEmpty,
      orElse: () => images.firstWhere((img) => img.imageUrl.trim().isNotEmpty, orElse: () => images.first),
    );
  }

  factory TenderDto.fromJson(Map<String, dynamic> json) {
    // Parsiranje ugniježđenih slika
    var rawImages = json['images'] as List?;
    List<TenderImageDto> parsedImages = rawImages != null
        ? rawImages.whereType<Map<String, dynamic>>().map(TenderImageDto.fromJson).toList()
        : const [];

    return TenderDto(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      maxBudget: JsonParser.readDouble(json['maxBudget']),
      deadline: DateTime.parse(json['deadline'] as String),
      createdByUserId: JsonParser.readString(json['createdByUserId']),
      createdByFullname: JsonParser.readString(json['createdByFullname'], fallback: 'Unknown'),
      status: TenderStatus.fromValue(json['status']), // Enum rješava svoje parsiranje
      totalBids: JsonParser.readInt(json['totalBids']),
      images: parsedImages,
      location: _parseLocation(json['location']),
      categoryId: JsonParser.readInt(json['categoryId']),
      categoryName: JsonParser.readString(json['categoryName'], fallback: 'No category'),
      postedAt: DateTime.parse(json['postedAt'] as String),
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'maxBudget': maxBudget,
        'deadline': deadline.toIso8601String(),
        'createdByUserId': createdByUserId,
        'createdByFullname': createdByFullname,
        'status': status.value, // Šalje int ili string zavisno od enuma
        'totalBids': totalBids,
        'images': images.map((img) => img.toJson()).toList(),
        'location': location.toJson(),
        'categoryId': categoryId,
        'categoryName': categoryName,
        'postedAt': postedAt.toIso8601String(),
        'profileImageUrl': profileImageUrl,
      };

  // Pretvara TenderDto u model koji direktno očekuje tvoj UI Card Widget
  TenderCardModel toCardModel() {
    return TenderCardModel(
      id: id,
      title: title,
      category: categoryName,
      status: status, // Nema potrebe za mapStatus metodom ako koristiš isti enum
      valueKM: maxBudget,
      deadline: deadline,
      postedAt: postedAt,
      tags: location != null ? [location!.name, location!.country] : const [],
      imageUrl: DioClient.resolveImageUrl(primaryImage?.imageUrl),
      locationName: location.displayLabel,
    );
  }

  static LocationDto _parseLocation(dynamic value) {
 
      return LocationDto.fromJson(value);
    
  }
}


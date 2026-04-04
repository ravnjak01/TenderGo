import 'package:tendergo_admin/models/enums/tenderstatus.dart';
import 'package:tendergo_admin/models/dto/tender_image_dto.dart';

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
  final String locationName;
  final String country;
  final int categoryId;
  final String categoryName;
  final DateTime postedAt; 
  final TenderImageDto? images;
  TenderDto({
    required this.id,
    required this.title,
    required this.description,
    required this.maxBudget,
    required this.deadline,
    required this.createdByUserId,
    required this.createdByFullname,
    required this.status,
    required this.totalBids,
    required this.locationName,
    required this.country,
    required this.categoryId,
    required this.categoryName,
    required this.postedAt,
    required this.images,
  });



factory TenderDto.fromJson(Map<String, dynamic> json) {
  return TenderDto(
    id: json['id'] as int,
    title: json['title'] as String,
    description: json['description'] as String?, 
    maxBudget: (json['maxBudget'] as num).toDouble(),
    deadline: DateTime.parse(json['deadline'] as String),
    createdByUserId: json['createdByUserId'] as String,
    createdByFullname: json['createdByFullname'] as String,
    status: TenderStatus.fromInt(json['status'] as int),
    totalBids: json['totalBids'] as int,
    locationName: json['locationName'] as String? ?? "Not specified", 
    country: json['country'] as String? ?? "Not specified",
    categoryId: json['categoryId'] as int,
    // Ispravljeno malo 'c' i dodano '?'
    categoryName: json['categoryName'] as String? ?? "No category",
    postedAt: DateTime.parse(json['postedAt'] as String),
   images: (json['images'] != null && (json['images'] as List).isNotEmpty)
        ? TenderImageDto.fromJson(json['images'][0]) 
        : null,
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
        'status': status.index,
        'totalBids': totalBids,
        'locationName': locationName,
        'country': country,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'postedAt': postedAt.toIso8601String(),
        'images': images != null
            ? {
                'url': images!.imageUrl,
                'isPrimary': images!.isPrimary,
              }
            : null,
      };
}
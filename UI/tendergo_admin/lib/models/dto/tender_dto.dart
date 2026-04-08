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

  static String? _readStringValue(dynamic value) {
    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    if (value is Map<String, dynamic>) {
      return _firstNonEmptyString([
        value['name'],
        value['title'],
        value['city'],
        value['label'],
      ]);
    }

    return null;
  }

  static String? _firstNonEmptyString(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final value = _readStringValue(candidate);
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  static int _readCategoryId(Map<String, dynamic> json) {
    final rawCategoryId = json['categoryId'] ??
        (json['category'] is Map<String, dynamic>
            ? (json['category'] as Map<String, dynamic>)['id']
            : null);

    if (rawCategoryId is int) {
      return rawCategoryId;
    }

    if (rawCategoryId is num) {
      return rawCategoryId.toInt();
    }

    return 0;
  }



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
    locationName: _firstNonEmptyString([
        json['locationName'],
        json['location'],
        json['locationDto'],
      ]) ??
      'Not specified',
    country: _firstNonEmptyString([
        json['country'],
        json['locationCountry'],
        json['location'] is Map<String, dynamic>
          ? (json['location'] as Map<String, dynamic>)['country']
          : null,
        json['locationDto'] is Map<String, dynamic>
          ? (json['locationDto'] as Map<String, dynamic>)['country']
          : null,
      ]) ??
      'Not specified',
    categoryId: _readCategoryId(json),
    categoryName: _firstNonEmptyString([
        json['categoryName'],
        json['category'],
        json['categoryDto'],
      ]) ??
      'No category',
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
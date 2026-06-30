import 'package:tendergo/shared/models/dto/tender_image_dto.dart';

class TenderInsertRequest {
  final String title;
  final double maxBudget; 
  final int locationId;
  final String? description; 
  final int categoryId;
  final DateTime deadline;
  final List<TenderImageDto> images;

  TenderInsertRequest({
    required this.title,
    required this.maxBudget,
    required this.locationId,
    this.description,
    required this.categoryId,
    required this.deadline,
    this.images = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'maxBudget': maxBudget, 
      'locationId': locationId,
      'description': description, 
      'categoryId': categoryId,
      'deadline': deadline.toIso8601String(),
      'images': images
          .map(
            (image) => {
              'imageUrl': image.imageUrl,
              'imageHash': image.imageHash,
            },
          )
          .toList(),
    };
  }
}
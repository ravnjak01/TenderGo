import 'dart:convert';
import 'dart:typed_data';

class TenderInsertRequest {
  final String title;
  final double maxBudget;
  final int locationId;
  final String? description;
  final int categoryId;
  final DateTime deadline;
  final List<Uint8List>? imageBytes;

  TenderInsertRequest({
    required this.title,
    required this.maxBudget,
    required this.locationId,
    this.description,
    required this.categoryId,
    required this.deadline,
    this.imageBytes, 
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'maxBudget': maxBudget,
      'locationId': locationId,
      'description': description,
      'categoryId': categoryId,
      'deadline': deadline.toIso8601String(),
      'imageBytes': imageBytes?.map((bytes) => base64Encode(bytes)).toList(),
    };
  }

}
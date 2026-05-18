import 'dart:convert';
import 'dart:typed_data';

class TenderInsertRequest {
  final String title;
  final double maxBudget;
  final int locationId;
  final String? description;
  final int categoryId;
  final DateTime deadline;
  // Promijenjeno u nullable List<Uint8List>? kako bi se poklopilo sa konstruktorom i slanjem null vrijednosti
  final List<Uint8List>? imageBytes;

  TenderInsertRequest({
    required this.title,
    required this.maxBudget,
    required this.locationId,
    this.description,
    required this.categoryId,
    required this.deadline,
    this.imageBytes, // Ovdje je dozvoljen null, zato polje gore mora biti nullable
  });

  /// Convert TenderInsertRequest to JSON Map
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'maxBudget': maxBudget,
      'locationId': locationId,
      'description': description,
      'categoryId': categoryId,
      'deadline': deadline.toIso8601String(),
      // Koristimo ?. operator jer imageBytes može biti null
      'imageBytes': imageBytes?.map((bytes) => base64Encode(bytes)).toList(),
    };
  }

}
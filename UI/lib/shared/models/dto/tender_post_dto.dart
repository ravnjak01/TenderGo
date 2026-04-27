import 'dart:convert';

class TenderInsertRequest {
  final String title;
  final double maxBudget;
  final String locationName;
  final String? description;
  final int categoryId;
  final DateTime deadline;
  final List<List<int>>? imageBytes;

  TenderInsertRequest({
    required this.title,
    required this.maxBudget,
    required this.locationName,
    this.description,
    required this.categoryId,
    required this.deadline,
    this.imageBytes,
  });

  /// Convert TenderInsertRequest to JSON
  Map<String, dynamic> toJson() {
    final normalizedImageBytes =
        imageBytes
            ?.map((bytes) => bytes.toList())
            .where((bytes) => bytes.isNotEmpty)
            .toList() ??
        const <List<int>>[];

    final encodedImageBytes = normalizedImageBytes
        .map(base64Encode)
        .toList(growable: false);

    return {
      'title': title,
      'maxBudget': maxBudget,
      'locationName': locationName,
      'description': description,
      'categoryId': categoryId,
      'deadline': deadline.toIso8601String(),
      'imageBytes': encodedImageBytes,
    };
  }

  /// Create TenderInsertRequest from JSON
  factory TenderInsertRequest.fromJson(Map<String, dynamic> json) {
    return TenderInsertRequest(
      title: json['title'] as String,
      maxBudget: (json['maxBudget'] as num).toDouble(),
      locationName: json['locationName'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      imageBytes: (json['imageBytes'] ?? json['imageUrls']) != null
          ? List<List<int>>.from(
              ((json['imageBytes'] ?? json['imageUrls']) as List).map((x) {
                if (x is String) {
                  return base64Decode(x);
                }
                return List<int>.from(x as List);
              }),
            )
          : null,
    );
  }
}



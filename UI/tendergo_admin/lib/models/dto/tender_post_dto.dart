class TenderInsertRequest {
  final String title;
  final double maxBudget;
  final String location;
  final String? description;
  final int categoryId;
  final DateTime deadline;
  final List<String>? imageUrls;

  TenderInsertRequest({
    required this.title,
    required this.maxBudget,
    required this.location,
    this.description,
    required this.categoryId,
    required this.deadline,
    this.imageUrls,
  });

  /// Convert TenderInsertRequest to JSON
Map<String, dynamic> toJson() {
  return {
    'title': title,
    'maxBudget': maxBudget,
    'location': location,
    'description': description,
    'categoryId': categoryId,
    'deadline': deadline.toIso8601String(),
    'imageUrls': imageUrls ?? [],
  };
}

  /// Create TenderInsertRequest from JSON
  factory TenderInsertRequest.fromJson(Map<String, dynamic> json) {
    return TenderInsertRequest(
      title: json['title'] as String,
      maxBudget: (json['maxBudget'] as num).toDouble(),
      location: json['location'] as String,
      description: json['description'] as String?,
      categoryId: json['categoryId'] as int,
      deadline: DateTime.parse(json['deadline'] as String),
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List)
          : null,
    );
  }
}

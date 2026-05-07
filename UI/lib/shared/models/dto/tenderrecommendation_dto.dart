class TenderRecommendation {
  final int tenderId;
  final String title;
  final String? description;
  final double maxBudget;
  final DateTime deadline;
  final String status;
  final String? category;
  final String? country;
  final String? locationName;
  final String? thumbnailUrl;
  final double similarityScore;

  const TenderRecommendation({
    required this.tenderId,
    required this.title,
    this.description,
    required this.maxBudget,
    required this.deadline,
    required this.status,
    this.category,
    this.country,
    this.locationName,
    this.thumbnailUrl,
    required this.similarityScore,
  });

  factory TenderRecommendation.fromJson(Map<String, dynamic> json) {
    return TenderRecommendation(
      tenderId:        json['tenderId'] as int,
      title:           json['title'] as String,
      description:     json['description'] as String?,
      maxBudget:       (json['maxBudget'] as num).toDouble(),
      deadline:        DateTime.parse(json['deadline'] as String),
      status:          json['status'] as String,
      category:        json['category'] as String?,
      country:         json['country'] as String?,
      locationName:    json['locationName'] as String?,
      thumbnailUrl:    json['thumbnailUrl'] as String?,
      similarityScore: (json['similarityScore'] as num).toDouble(),
    );
  }

  /// How many days until the deadline
  int get daysUntilDeadline => deadline.difference(DateTime.now()).inDays;

  /// Budget formatted as currency string
  String get budgetFormatted {
    if (maxBudget >= 1000000) return '${(maxBudget / 1000000).toStringAsFixed(1)}M';
    if (maxBudget >= 1000) return '${(maxBudget / 1000).toStringAsFixed(0)}k';
    return maxBudget.toStringAsFixed(0);
  }

  /// Similarity as a percentage string
  String get matchPercent => '${(similarityScore * 100).toStringAsFixed(0)}%';
}
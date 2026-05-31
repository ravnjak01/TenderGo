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
  final String? recommendationReason;
  final List<String> recommendationSignals;

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
    this.recommendationReason,
    this.recommendationSignals = const [],
  });

  factory TenderRecommendation.fromJson(Map<String, dynamic> json) {
    final rawSignals = json['recommendationSignals'] ??
        json['RecommendationSignals'] ??
        json['recommendation_signals'];

    return TenderRecommendation(
      tenderId: _number(json, 'tenderId', 'TenderId').toInt(),
      title: (json['title'] ?? json['Title']) as String,
      description: (json['description'] ?? json['Description']) as String?,
      maxBudget: _number(json, 'maxBudget', 'MaxBudget').toDouble(),
      deadline:
          DateTime.parse((json['deadline'] ?? json['Deadline']) as String),
      status: (json['status'] ?? json['Status']) as String,
      category: (json['category'] ?? json['Category']) as String?,
      country: (json['country'] ?? json['Country']) as String?,
      locationName: (json['locationName'] ??
          json['LocationName'] ??
          json['city'] ??
          json['City']) as String?,
      thumbnailUrl: (json['thumbnailUrl'] ?? json['ThumbnailUrl']) as String?,
      similarityScore:
          _number(json, 'similarityScore', 'SimilarityScore').toDouble(),
      recommendationReason: (json['recommendationReason'] ??
          json['RecommendationReason'] ??
          json['recommendation_reason']) as String?,
      recommendationSignals: rawSignals is List
          ? rawSignals
              .whereType<String>()
              .where((signal) => signal.trim().isNotEmpty)
              .toList()
          : const [],
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

  bool get hasExplanation =>
      (recommendationReason?.trim().isNotEmpty ?? false) ||
      recommendationSignals.isNotEmpty;

  String get explanationText {
    final reason = recommendationReason?.trim();
    if (reason != null && reason.isNotEmpty) return reason;

    if (category != null && category!.trim().isNotEmpty) {
      return 'Recommended because it matches your recent activity in ${category!.trim()}.';
    }

    return 'Recommended because it has a $matchPercent match with your tender activity.';
  }

  static num _number(
    Map<String, dynamic> json,
    String camelCaseKey,
    String pascalCaseKey,
  ) {
    return (json[camelCaseKey] ?? json[pascalCaseKey]) as num;
  }
}

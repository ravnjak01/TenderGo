enum ActivityRecommendType {
  tenderViewed,
  tenderSearch;

  String toJson() {
    switch (this) {
      case ActivityRecommendType.tenderViewed:
        return 'TenderViewed';
      case ActivityRecommendType.tenderSearch:
        return 'TenderSearch';
    }
  }
}

class ActivityLogRequest {
  final ActivityRecommendType activityType;
  final int? tenderId;
  final String? searchQuery;
  final int? durationSeconds;

  ActivityLogRequest({
    required this.activityType,
    this.tenderId,
    this.searchQuery,
    this.durationSeconds,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'activityType': activityType.toJson(),
    };

    if (tenderId != null) {
      data['tenderId'] = tenderId;
    }

    if (searchQuery != null) {
      data['searchQuery'] = searchQuery;
    }

    if (durationSeconds != null) {
      data['durationSeconds'] = durationSeconds;
    }

    return data;
  }
}
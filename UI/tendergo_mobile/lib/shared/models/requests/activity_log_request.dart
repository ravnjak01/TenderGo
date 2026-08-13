class ActivityLogRequest {
  final String activityType; 
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
    final Map<String, dynamic> data = {'activityType': activityType};

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

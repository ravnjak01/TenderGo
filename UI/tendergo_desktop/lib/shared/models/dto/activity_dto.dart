class ActivityDto {
  final DateTime createdAt;
  final String userName;
  final ActivityType activityType;
  final String action;
  final String? details;

  ActivityDto({
    required this.createdAt,
    required this.userName,
    required this.activityType,
    required this.action,
    this.details,
  });

  factory ActivityDto.fromJson(Map<String, dynamic> json) {
    return ActivityDto(
      createdAt: DateTime.parse(
        json['createdAt'] as String,
      ),
      userName: json['userName'] as String? ?? '',
      activityType: parseActivityType(
      json['activityType'],
    ),
      action: json['action'] as String? ?? '',
      details: json['details'] as String?,
    );
  }
}
enum ActivityType {
  userRegistered,
  tenderCreated,
  bidSubmitted,
}

ActivityType parseActivityType(dynamic value) {
  if (value is int) {
    switch (value) {
      case 0:
        return ActivityType.userRegistered;
      case 1:
        return ActivityType.tenderCreated;
      case 2:
        return ActivityType.bidSubmitted;
      default:
        return ActivityType.userRegistered;
    }
  }

  final text = value?.toString();

  switch (text) {
    case 'UserRegistered':
      return ActivityType.userRegistered;
    case 'TenderCreated':
      return ActivityType.tenderCreated;
    case 'BidSubmitted':
      return ActivityType.bidSubmitted;
    default:
      return ActivityType.userRegistered;
  }
}

extension ActivityTypeX on ActivityType {
  String get label {
    switch (this) {
      case ActivityType.userRegistered:
        return 'Korisnik registrovan';
      case ActivityType.tenderCreated:
        return 'Tender kreiran';
      case ActivityType.bidSubmitted:
        return 'Ponuda poslana';
    }
  }
}
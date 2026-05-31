class NotificationDto {
  final int id;
  final String title;
  final String message;

  /// e.g. bid_received | bid_accepted | bid_rejected | bid_withdrawn |
  ///       tender_closed | tender_cancelled | tender_awarded | general
  final String type;
  final bool isRead;
  final DateTime createdAt;

  /// When set, tapping the notification navigates to tender details.
  final int? tenderId;

  const NotificationDto({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.tenderId,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as int,
      title: (json['title'] as String?)?.trim() ?? '',
      message: (json['message'] as String?)?.trim() ?? '',
      type: (json['type'] as String?)?.trim() ?? 'general',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      tenderId: json['tenderId'] as int?,
    );
  }

  NotificationDto copyWith({bool? isRead}) => NotificationDto(
        id: id,
        title: title,
        message: message,
        type: type,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        tenderId: tenderId,
      );
}

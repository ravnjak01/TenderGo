import 'package:tendergo/shared/models/dto/activity_dto.dart';

class AdminDashboardDto {
  final int totalUsers;
  final int activeTenders;
  final int totalCategories;
  final int totalLocations;
  final List<ActivityDto> recentActivities;

  const AdminDashboardDto({
    required this.totalUsers,
    required this.activeTenders,
    required this.totalCategories,
    required this.totalLocations,
    required this.recentActivities,
  });

  factory AdminDashboardDto.fromJson(Map<String, dynamic> json) {
    final rawActivities = json['recentActivities'];

    return AdminDashboardDto(
      totalUsers: json['totalUsers'] as int? ?? 0,
      activeTenders: json['activeTenders'] as int? ?? 0,
      totalCategories: json['totalCategories'] as int? ?? 0,
      totalLocations: json['totalLocations'] as int? ?? 0,
      recentActivities: rawActivities is List
          ? rawActivities
              .map(
                (x) => ActivityDto.fromJson(
                  Map<String, dynamic>.from(x as Map),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class BanRequest {
  final String reason;

  BanRequest({required this.reason});

  Map<String, dynamic> toJson() {
    return {
      'reason': reason,
    };
  }
}

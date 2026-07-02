import 'package:tendergo/shared/models/enums/tenderstatus.dart';

class AdminTenderDto {
  final int id;
  final String title;
  final String createdByUserFullName;
  final DateTime deadline;
  final double maxBudget; 
  final TenderStatus status;

  AdminTenderDto({
    required this.id,
    required this.title,
    required this.createdByUserFullName,
    required this.deadline,
    required this.maxBudget,
    required this.status,
  });

 
  factory AdminTenderDto.fromJson(Map<String, dynamic> json) {
  final backendStatus = json['status'] as int? ?? 1; 
  final statusIndex = backendStatus - 1;

  final tenderStatus = statusIndex >= 0 && statusIndex < TenderStatus.values.length
      ? TenderStatus.values[statusIndex]
      : TenderStatus.open;
    return AdminTenderDto(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      createdByUserFullName: json['createdByUserFullName'] as String? ?? '',
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline'] as String) 
          : DateTime.now(),
      maxBudget: (json['maxBudget'] as num? ?? 0.0).toDouble(),
      status: tenderStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdByUserFullName': createdByUserFullName,
      'deadline': deadline.toIso8601String(),
      'maxBudget': maxBudget,
    };
  }
}
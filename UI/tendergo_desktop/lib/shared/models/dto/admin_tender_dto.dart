import 'package:tendergo/shared/core/utils/json_parser.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';

class AdminTenderDto {
  final int id;
  final String title;
  final String createdByUserFullname; // Usklađeno sa nazvom na TenderDto
  final DateTime deadline;
  final double maxBudget;
  final TenderStatus status;

  const AdminTenderDto({
    required this.id,
    required this.title,
    required this.createdByUserFullname,
    required this.deadline,
    required this.maxBudget,
    required this.status,
  });

  factory AdminTenderDto.fromJson(Map<String, dynamic> json) {
    return AdminTenderDto(
      id: JsonParser.readInt(json['id']),
      title: JsonParser.readString(json['title']),
      createdByUserFullname: JsonParser.readString(
      json['createdByUserFullName'],
        fallback: 'N/A',
      ),
      deadline: JsonParser.readDateTime(json['deadline']),
      maxBudget: JsonParser.readDouble(json['maxBudget']),
      status: TenderStatus.fromValue(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdByUserFullname': createdByUserFullname,
      'deadline': deadline.toIso8601String(),
      'maxBudget': maxBudget,
      'status': status.value,
    };
  }
}
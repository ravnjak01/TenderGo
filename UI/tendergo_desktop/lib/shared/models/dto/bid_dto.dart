import 'package:tendergo/shared/core/utils/json_parser.dart';
import 'package:tendergo/shared/models/enums/application_status.dart';

class BidDto {
  final int id;
  final int tenderId;
  final String tenderTitle;
  final String submittedByUserId;
  final String submittedByUserName;
  final double offeredPrice;
  final DateTime submittedAt;
  final ApplicationStatus status;
  final String? proposal;
  final int deliveryDays;

  const BidDto({
    required this.id,
    required this.tenderId,
    required this.tenderTitle,
    required this.submittedByUserId,
    required this.submittedByUserName,
    required this.offeredPrice,
    required this.submittedAt,
    required this.status,
    this.proposal,
    required this.deliveryDays,
  });

  factory BidDto.fromJson(Map<String, dynamic> json) {
    return BidDto(
      id: JsonParser.readInt(json['id']),
      tenderId: JsonParser.readInt(json['tenderId']),
      tenderTitle: JsonParser.readString(json['tenderTitle'], fallback: 'Untitled tender'),
      submittedByUserId: JsonParser.readString(json['submittedByUserId']),
      submittedByUserName: JsonParser.readString(json['submittedByUserName']),
      offeredPrice: JsonParser.readDouble(json['offeredPrice']),
      submittedAt: json['submittedAt'] != null 
          ? DateTime.parse(json['submittedAt'] as String) 
          : DateTime.fromMillisecondsSinceEpoch(0),
      status: ApplicationStatus.fromValue(json['status']),
      proposal: JsonParser.readNullableString(json['proposal']),
      deliveryDays: JsonParser.readInt(json['deliveryDays']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenderId': tenderId,
        'tenderTitle': tenderTitle,
        'submittedByUserId': submittedByUserId,
        'submittedByUserName': submittedByUserName,
        'offeredPrice': offeredPrice,
        'submittedAt': submittedAt.toIso8601String(),
        'status': status.name,
        'proposal': proposal,
        'deliveryDays': deliveryDays,
      };
}
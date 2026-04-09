import 'package:tendergo_admin/models/dto/tender_dto.dart';
import 'package:tendergo_admin/models/enums/tenderstatus.dart';

class TenderCardModel {
  const TenderCardModel({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.valueKM,
    required this.deadline,
    required this.postedAt,
    required this.tags,
    this.imageUrl,
    required this.location
  });

  final String id;
  final String title;
  final String category;
  final TenderStatus status;
  final double valueKM;
  final DateTime deadline;
  final DateTime postedAt;
  final List<String> tags;
  final String? imageUrl; // null → show placeholder
  final String location; 

  factory TenderCardModel.fromDTO(TenderDto dto) {
    return TenderCardModel(
      id: dto.id.toString(), // Pretvaraš int u String na jednom mjestu
      title: dto.title,
      category: dto.categoryName,
      valueKM: dto.maxBudget,
      status: dto.status,
      deadline: dto.deadline,
      postedAt: dto.postedAt,
      tags: [], 
      imageUrl: dto.primaryImage?.imageUrl, 
      location: dto.locationName,
    );
  }
}
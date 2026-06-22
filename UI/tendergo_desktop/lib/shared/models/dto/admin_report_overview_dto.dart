class AdminReportOverviewDto {
  final double totalTenderValue  ;
  final double tenderRealizationPercentage;
  final int cancelledTenderCount;

  AdminReportOverviewDto({
    required this.totalTenderValue,
    required this.tenderRealizationPercentage,
    required this.cancelledTenderCount,
  });

  factory AdminReportOverviewDto.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AdminReportOverviewDto(
      totalTenderValue: parseDouble(json['totalTenderValue']),
      tenderRealizationPercentage: parseDouble(json['tenderRealizationPercentage']),
      cancelledTenderCount: parseInt(json['cancelledTenderCount']),
    );
  }
}
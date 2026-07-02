class AdminReportOverviewDto {
  final double totalTenderValue;
  final double tenderRealizationPercentage;
  final int cancelledTenderCount;

  AdminReportOverviewDto({
    required this.totalTenderValue,
    required this.tenderRealizationPercentage,
    required this.cancelledTenderCount,
  });

  factory AdminReportOverviewDto.fromJson(Map<String, dynamic> json) {
    
    dynamic getValue(Map<String, dynamic> json, String camelKey, String pascalKey) {
      return json[camelKey] ?? json[pascalKey];
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0; 
      if (value is num) return value.toDouble(); 
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0; 
      if (value is num) return value.toInt(); 
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AdminReportOverviewDto(
      totalTenderValue: parseDouble(getValue(json, 'totalTenderValue', 'TotalTenderValue')),
      tenderRealizationPercentage: parseDouble(getValue(json, 'tenderRealizationPercentage', 'TenderRealizationPercentage')),
      cancelledTenderCount: parseInt(getValue(json, 'cancelledTenderCount', 'CancelledTenderCount')),
    );
  }
}
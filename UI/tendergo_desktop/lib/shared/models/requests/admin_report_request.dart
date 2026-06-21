class AdminReportRequest {
  final String? startDate;
  final String? endDate;
  final String? type;

  AdminReportRequest({this.startDate, this.endDate, this.type});

  Map<String, dynamic> toJson() {
    return {
      'startDate': startDate,
      'endDate': endDate,
      'type': type,
    };
  }
}
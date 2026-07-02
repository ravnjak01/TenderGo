// admin_report_request.dart
class AdminReportRequest {
  final int locationId;
  final DateTime from;
  final DateTime to;

  const AdminReportRequest({
    required this.locationId,
    required this.from,
    required this.to,
  });

  Map<String, dynamic> toJson() {
    String pad(int value) => value.toString().padLeft(2, '0');

    final fromString = "${from.year}-${pad(from.month)}-${pad(from.day)}";
    final toString = "${to.year}-${pad(to.month)}-${pad(to.day)}";

    return {
      'locationId': locationId,
      'from': fromString, 
      'to': toString,     
    };
  }
}
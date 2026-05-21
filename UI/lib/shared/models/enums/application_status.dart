// lib/shared/models/enums/application_status.dart
enum ApplicationStatus {
  pending(1),
  accepted(2),
  rejected(3),
  withdrawn(4);

  final int value;
  const ApplicationStatus(this.value);

  static ApplicationStatus fromValue(dynamic val) {
    if (val is int) {
      return ApplicationStatus.values.firstWhere((e) => e.value == val, orElse: () => pending);
    }
    if (val is String) {
      final str = val.toLowerCase().trim();
      return ApplicationStatus.values.firstWhere((e) => e.name.toLowerCase() == str, orElse: () => pending);
    }
    return pending;
  }
}
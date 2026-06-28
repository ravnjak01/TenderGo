
/// 1. Osnovni Enum za status tendera
enum TenderStatus {
  open(1),
  closed(2),
  awarded(3),
  cancelled(4);

  final int value;
  const TenderStatus(this.value);

  static TenderStatus fromValue(dynamic val) {
    if (val is int) {
      return TenderStatus.values.firstWhere(
        (e) => e.value == val,
        orElse: () => TenderStatus.open,
      );
    }
    if (val is String) {
      final normalized = val.trim().toLowerCase();
      for (final status in TenderStatus.values) {
        if (status.name.toLowerCase() == normalized) return status;
      }
      const labels = {
        'open': TenderStatus.open,
        'closed': TenderStatus.closed,
        'awarded': TenderStatus.awarded,
        'cancelled': TenderStatus.cancelled,
      };
      return labels[normalized] ?? TenderStatus.open;
    }
    return TenderStatus.open;
  }
  
}


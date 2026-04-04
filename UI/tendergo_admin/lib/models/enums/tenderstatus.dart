import 'package:flutter/material.dart';

/// 1. Osnovni Enum za status tendera
enum TenderStatus {
  draft(1),
  open(2),
  closed(3),
  award(4),
  cancelled(5),
  archived(6);

  final int value;
  const TenderStatus(this.value);

  /// Helper metoda za konverziju integera sa API-ja u Enum
  static TenderStatus fromInt(int value) {
    return TenderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TenderStatus.draft,
    );
  }
}

/// 2. Ekstenzija koja dodaje UI logiku (boje i tekst) na TenderStatus
extension TenderStatusX on TenderStatus {
  String get label {
    switch (this) {
      case TenderStatus.draft:     return 'Draft';
      case TenderStatus.open:      return 'Open';
      case TenderStatus.closed:    return 'Closed';
      case TenderStatus.award:     return 'Awarded';
      case TenderStatus.cancelled: return 'Cancelled';
      case TenderStatus.archived:  return 'Archived';
    }
  }

  Color get badgeBg {
    switch (this) {
      case TenderStatus.open:      return const Color(0xFFEAF3DE); // Zelena
      case TenderStatus.draft:     return const Color(0xFFE8F4FD); // Plava
      case TenderStatus.award:     return const Color(0xFFF1F8E9); // Svijetlo zelena
      case TenderStatus.closed:    
      case TenderStatus.cancelled: 
      case TenderStatus.archived:  return const Color(0xFFF1EFE8); // Siva
    }
  }

  Color get badgeFg {
    switch (this) {
      case TenderStatus.open:      return const Color(0xFF3B6D11); // Tamno zelena
      case TenderStatus.draft:     return const Color(0xFF1976D2); // Tamno plava
      case TenderStatus.award:     return const Color(0xFF2E7D32); // Forbes zelena
      case TenderStatus.closed:    
      case TenderStatus.cancelled: 
      case TenderStatus.archived:  return const Color(0xFF5F5E5A); // Tamno siva
    }
  }
}


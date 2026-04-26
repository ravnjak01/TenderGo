import 'package:flutter/material.dart';

/// 1. Osnovni Enum za status tendera
enum TenderStatus {
  open(1),
  closed(2),
  award(3),
  cancelled(4);

  final int value;
  const TenderStatus(this.value);

  /// Helper metoda za konverziju integera sa API-ja u Enum
  static TenderStatus fromInt(int value) {
    return TenderStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TenderStatus.open,
    );
  }
}

/// 2. Ekstenzija koja dodaje UI logiku (boje i tekst) na TenderStatus
extension TenderStatusX on TenderStatus {
  String get label {
    switch (this) {
      case TenderStatus.open:      return 'Open';
      case TenderStatus.closed:    return 'Closed';
      case TenderStatus.award:     return 'Awarded';
      case TenderStatus.cancelled: return 'Cancelled';
    }
  }

  Color get badgeBg {
    switch (this) {
      case TenderStatus.open:      return const Color(0xFFEAF3DE); // Zelena
      case TenderStatus.award:     return const Color(0xFFF1F8E9); // Svijetlo zelena
      case TenderStatus.closed:    
      case TenderStatus.cancelled: return const Color(0xFFFFEBEE); 
    }
  }

  Color get badgeFg {
    switch (this) {
      case TenderStatus.open:      return const Color(0xFF3B6D11); // Tamno zelena
      case TenderStatus.award:     return const Color(0xFF2E7D32); // Forbes zelena
      case TenderStatus.closed:    
      case TenderStatus.cancelled: return const Color(0xFFD32F2F); 
    }
  }
}


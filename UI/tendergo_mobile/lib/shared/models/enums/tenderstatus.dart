import 'package:flutter/material.dart';

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

extension TenderStatusX on TenderStatus {
  String get label {
    switch (this) {
      case TenderStatus.open:      return 'Open';
      case TenderStatus.closed:    return 'Closed';
      case TenderStatus.awarded:   return 'Awarded';
      case TenderStatus.cancelled: return 'Cancelled';
    }
  }

  Color get badgeBg {
    switch (this) {
      case TenderStatus.open:      return const Color(0xFFEAF3DE); // Zelena
      case TenderStatus.awarded:   return const Color(0xFFF1F8E9); // Svijetlo zelena
      case TenderStatus.closed:    
      case TenderStatus.cancelled: return const Color(0xFFFFEBEE); 
    }
  }

  Color get badgeFg {
    switch (this) {
      case TenderStatus.open:      return const Color(0xFF3B6D11); // Tamno zelena
      case TenderStatus.awarded:   return const Color(0xFF2E7D32); // Forbes zelena
      case TenderStatus.closed:    
      case TenderStatus.cancelled: return const Color(0xFFD32F2F); 
    }
  }

 
}


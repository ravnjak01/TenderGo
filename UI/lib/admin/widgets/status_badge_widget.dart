import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status});
  final TenderStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.badgeBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: status.badgeFg,
        ),
      ),
    );
  }
}

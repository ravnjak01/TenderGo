import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';


class TenderTag extends StatelessWidget {
  final String label;
  final Color? backgroundColor;

  const TenderTag({
    super.key,
    required this.label,
    this.backgroundColor,
  });

 

  @override
  Widget build(BuildContext context) {
    final theme = themeForCategory(label);
    const primaryColor = Color(0xFF185FA5);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: primaryColor.withValues(alpha:0.1),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF5F5E5A),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
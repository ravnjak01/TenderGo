import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.label,
    required this.isPrimary,
    this.onTap,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFE6F1FB) : Colors.transparent,
          border: Border.all(
            color: isPrimary ? const Color(0xFF185FA5) : const Color(0xFFB4B2A9),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isPrimary ? const Color(0xFF185FA5) : const Color(0xFF5F5E5A),
          ),
        ),
      ),
    );
  }
}
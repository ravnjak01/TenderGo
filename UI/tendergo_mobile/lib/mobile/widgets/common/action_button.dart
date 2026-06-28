import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.isPrimary,
    this.onTap,
    this.icon,
    this.isDestructive = false,
    this.width,
    this.showLabel = true,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isDestructive;
  final double? width;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final foreground = isDestructive
        ? const Color(0xFFDC2626)
        : isPrimary
            ? const Color(0xFF185FA5)
            : const Color(0xFF5F5E5A);
    final border = isDestructive
        ? const Color(0xFFDC2626)
        : isPrimary
            ? const Color(0xFF185FA5)
            : const Color(0xFFB4B2A9);
    final background = isPrimary && !isDestructive
        ? const Color(0xFFE6F1FB)
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Container(
          width: width,
          height: 30,
          padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 0),
          decoration: BoxDecoration(
            color: background,
            border: Border.all(color: border, width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Row(
  mainAxisSize: MainAxisSize.min,
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    if (icon != null) ...[
      Icon(icon, size: 12, color: foreground),
      if (showLabel) const SizedBox(width: 3),
    ],
    if (showLabel)
      Flexible( 
        child: Text(
          label,
          style: TextStyle(fontSize: 12, color: foreground),
          maxLines: 1, 
          overflow: TextOverflow.ellipsis, 
        ),
      ),
  ],
),
        ),
      );
  }
}


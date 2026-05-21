import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';

class AppBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;

  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isAdmin = label.toLowerCase() == 'admin';
    final textTheme = Theme.of(context).textTheme;
    final bg = backgroundColor ??
        (isAdmin ? AppColors.infoSurface : AppColors.surfaceVariant);
    final fg = foregroundColor ??
        (isAdmin ? AppColors.primary : AppColors.textSecondary);
    final border = borderColor ??
        (isAdmin ? AppColors.primary.withOpacity(0.4) : AppColors.outline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}


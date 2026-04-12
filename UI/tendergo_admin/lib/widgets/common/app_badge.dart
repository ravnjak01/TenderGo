import 'package:flutter/material.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';

class AppBadge extends StatelessWidget {
  final String label;
  const AppBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final isAdmin = label.toLowerCase() == 'admin';
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin ? AppColors.infoSurface : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.outline,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: textTheme.labelSmall?.copyWith(
          color: isAdmin ? AppColors.primary : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

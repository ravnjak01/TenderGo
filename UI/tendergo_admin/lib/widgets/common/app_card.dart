
  import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tendergo_admin/core/theme/app_theme.dart';

class AppCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const AppCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(icon, size: 15, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(
              height: 1, thickness: 1, color: AppColors.outline),
          ...children,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool monospace;
  final bool copyable;

  const InfoRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.copyable = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(letterSpacing: 0.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontFamily: monospace ? 'monospace' : null,
                letterSpacing: monospace ? 0.4 : 0,
              ),
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(
                  Icons.copy_rounded,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';

class DatepickerWidget extends StatelessWidget {
  final DateTime? deadline;
  final VoidCallback onTap;

  const DatepickerWidget({
    super.key,
    required this.deadline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: deadline != null ? AppColors.primary : AppColors.textSecondary.withOpacity(0.2),
            width: deadline != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: deadline != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(
              deadline == null
                  ? 'Select deadline date'
                  : '${deadline!.day.toString().padLeft(2, '0')} / '
                      '${deadline!.month.toString().padLeft(2, '0')} / '
                      '${deadline!.year}',
              style: TextStyle(
                color: deadline == null ? AppColors.textSecondary : AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';

class DatepickerWidget extends StatelessWidget {
  final DateTime? deadline;
  final ValueChanged<DateTime> onDateSelected;
  final String? errorText;

  const DatepickerWidget({
    super.key,
    required this.deadline,
    required this.onDateSelected,
    this.errorText,
  });

   Future<void> _showPicker(BuildContext context) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: deadline != null && !deadline!.isBefore(tomorrow)
          ? deadline!
          : tomorrow,
      firstDate: tomorrow,
      lastDate: now.add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final endOfDay = DateTime(
        picked.year,
        picked.month,
        picked.day,
        23,
        59,
        59,
      );
      onDateSelected(endOfDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: hasError
                    ? AppColors.error
                    : deadline != null
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.2),
                width: hasError || deadline != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: deadline != null
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Text(
                  deadline == null
                      ? 'Select deadline date'
                      : '${deadline!.day.toString().padLeft(2, '0')} / '
                            '${deadline!.month.toString().padLeft(2, '0')} / '
                            '${deadline!.year}',
                  style: TextStyle(
                    color: deadline == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
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
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                height: 1.2,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

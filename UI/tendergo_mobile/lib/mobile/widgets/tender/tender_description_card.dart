import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/mobile/widgets/tender/tender_section_label.dart';

class TenderDescriptionCard extends StatelessWidget {
  const TenderDescriptionCard({
    super.key,
    required this.description,
  });

  final String? description;

  @override
  Widget build(BuildContext context) {
    final finalDescription = (description ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TenderSectionLabel(
            icon: Icons.description_outlined,
            label: 'Description',
          ),
          const SizedBox(height: 12),
          Text(
            finalDescription.isEmpty
                ? 'No description provided.'
                : finalDescription,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

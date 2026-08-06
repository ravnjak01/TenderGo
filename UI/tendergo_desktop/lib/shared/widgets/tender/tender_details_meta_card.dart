import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/widgets/tender/tender_detail_formatters.dart';
import 'package:tendergo/shared/widgets/tender/tender_section_label.dart';

class TenderDetailsMetaCard extends StatelessWidget {
  const TenderDetailsMetaCard({
    super.key,
    required this.tender,
  });

  final TenderDto tender;

  @override
  Widget build(BuildContext context) {
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
            icon: Icons.info_outline,
            label: 'Tender Details',
          ),
          const SizedBox(height: 14),
          ..._buildDetailItems(context),
        ],
      ),
    );
  }

  List<Widget> _buildDetailItems(BuildContext context) {
    final items = [
      _DetailItem(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Budget',
        value: formatTenderBudget(tender.maxBudget),
      ),
      _DetailItem(
        icon: Icons.location_on_outlined,
        label: 'Location',
        value: tender.location?.name ?? 'Nepoznata lokacija',
      ),
      _DetailItem(
        icon: Icons.work_outline,
        label: 'Category',
        value: tender.categoryName,
      ),
      _DetailItem(
        icon: Icons.access_time,
        label: 'Posted',
        value: formatTenderDate(tender.postedAt),
      ),
      _DetailItem(
        icon: Icons.calendar_today_outlined,
        label: 'Deadline',
        value: formatTenderDate(tender.deadline),
      ),
    ];

    return items
        .asMap()
        .entries
        .expand((entry) => [
          _buildDetailRow(context, entry.value),
          if (entry.key < items.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(color: AppColors.outline, height: 1),
            ),
        ])
        .toList();
  }

  Widget _buildDetailRow(BuildContext context, _DetailItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(item.icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(
            item.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            item.value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;

  _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });
}

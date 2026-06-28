import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/mobile/widgets/tender/tender_detail_formatters.dart';
import 'package:tendergo/mobile/widgets/tender/tender_image_gallery.dart';
import 'package:tendergo/mobile/widgets/tender/tender_meta_item.dart';
import 'package:tendergo/mobile/widgets/tender/tender_section_label.dart';


class TenderInfoSection extends StatelessWidget {
  const TenderInfoSection({
    super.key,
    required this.tender,
    this.imageHeight = 260,
    this.titleStyle,
  });

  final TenderDto tender;
  final double imageHeight;

  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final imageUrls = extractTenderImageUrls(tender);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            tender.categoryName,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          tender.title,
          style: titleStyle ??
              Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
        ),
        const SizedBox(height: 14),

        // Meta row
        Wrap(
          spacing: 16,
          runSpacing: 10,
          children: [
            TenderMetaItem(
              icon: Icons.calendar_today_outlined,
              label: 'Posted ${formatTenderDate(tender.postedAt)}',
            ),
            TenderMetaItem(
              icon: Icons.location_on_outlined,
              label: tender.location.name,
            ),
            TenderMetaItem(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Budget: ${formatTenderBudget(tender.maxBudget)}',
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Image gallery
        if (imageUrls.isNotEmpty) ...[
          TenderImageGallery(imageUrls: imageUrls, height: imageHeight),
          const SizedBox(height: 24),
        ],

      ],
    );
  }
}


class TenderInfoCard extends StatelessWidget {
  const TenderInfoCard({
    super.key,
    required this.tender,
    this.imageHeight = 220,
  });

  final TenderDto tender;
  final double imageHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const TenderSectionLabel(
            icon: Icons.description_outlined,
            label: 'Tender Overview',
          ),
          const SizedBox(height: 14),
          TenderInfoSection(tender: tender, imageHeight: imageHeight),
        ],
      ),
    );
  }
}

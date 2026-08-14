import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/widgets/tender/tender_detail_formatters.dart';
import 'package:tendergo/shared/widgets/tender/tender_image_gallery.dart';
import 'package:tendergo/shared/widgets/tender/tender_meta_item.dart';
import 'package:tendergo/shared/widgets/tender/tender_section_label.dart';

class TenderInfoSection extends StatelessWidget {
  const TenderInfoSection({
    super.key,
    required this.tender,
    this.imageHeight = 260,
    this.titleStyle,
    this.showDescription = true,
  });

  final TenderDto tender;
  final double imageHeight;
  final bool showDescription;

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
          style:
              titleStyle ??
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
              icon: Icons.person_outline,
              label: 'Raspisivač: ${tender.createdByUserFullname}',
            ),
            
            TenderMetaItem(
              icon: Icons.location_on_outlined,
             label: tender.location?.name ?? 'Nepoznata lokacija',
            ),
          
          ],
        ),
        const SizedBox(height: 20),

        // Image gallery
        if (imageUrls.isNotEmpty) ...[
          TenderImageGallery(imageUrls: imageUrls, height: imageHeight),
          const SizedBox(height: 24),
        ],

        if (showDescription) ...[
          // Description
          const Text(
            'Opis projekta',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (tender.description ?? 'No description provided.').trim(),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ],
    );
  }
}


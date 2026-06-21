import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/widgets/tender/tender_details_meta_card.dart';
import 'package:tendergo/shared/widgets/tender/tender_info_section.dart';
import 'package:intl/intl.dart';
class AdminTenderDetailsScreen extends StatelessWidget {
  final TenderDto tender;

  const AdminTenderDetailsScreen({super.key, required this.tender});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Detalji tendera'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TenderInfoSection(
                    tender: tender,
                    imageHeight: 320,
                    showDescription: true,
                    titleStyle: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  TenderDetailsMetaCard(tender: tender),
                  const SizedBox(height: 24),
                  _TenderMetadataBlock(tender: tender),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TenderMetadataBlock extends StatelessWidget {
  const _TenderMetadataBlock({required this.tender});

  final TenderDto tender;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dodatne informacije',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            _MetadataCard(label: 'Raspisivač', value: tender.createdByFullname),
            _MetadataCard(
              label: 'Status',
              value: tender.status.toString().split('.').last,
            ),
            _MetadataCard(
              label: 'Rok za prijavu',
              value: DateFormat('dd.MM.yyyy.').format(tender.deadline),
            ),
            _MetadataCard(
              label: 'Vrijednost',
              value: '${tender.maxBudget.toStringAsFixed(0)} KM',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

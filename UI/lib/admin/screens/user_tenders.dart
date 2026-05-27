import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/enums/tenderstatus.dart';
import 'package:tendergo/shared/services/tender_service.dart';

class UserTendersScreen extends StatelessWidget {
  final String userId;
  final String userName;
  final TenderService tenderService;

  const UserTendersScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.tenderService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenders by $userName'),
        leading: const CustomBackButton(),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: tenderService.getByUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'Failed to load tenders. Please try again later.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final rawList = snapshot.data ?? [];

          // Sigurno mapiranje dynamic liste sa servisa u List<TenderDto>
          final List<TenderDto> tenders = rawList
              .whereType<Map<String, dynamic>>()
              .map((json) => TenderDto.fromJson(json))
              .toList();

          if (tenders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_late_outlined,
                    size: 64,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This user has no tenders.',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: tenders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final tender = tenders[index];
              return _buildTenderItem(context, tender);
            },
          );
        },
      ),
    );
  }

  Widget _buildTenderItem(BuildContext context, TenderDto tender) {
    // Koristimo tvoju ugrađenu metodu iz DTO-a za UI model kartice
    final cardModel = tender.toCardModel();
    final formattedDeadline = DateFormat('dd.MM.yyyy').format(cardModel.deadline);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            // Ovdje otvaraš detalje tendera kada završiš taj ekran, npr:
            // Navigator.push(context, MaterialPageRoute(builder: (_) => TenderDetailsScreen(id: tender.id)));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gornji dio: Slika (ako postoji) + Osnovne informacije
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prikaz primarne slike tendera
                  if (cardModel.imageUrl != null && cardModel.imageUrl!.isNotEmpty)
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          cardModel.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 100,
                      height: 100,
                      padding: const EdgeInsets.all(8),
                      child: _buildPlaceholderImage(),
                    ),
                  
                  // Naslov, Kategorija i Budžet
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cardModel.category,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              _buildStatusBadge(context, cardModel.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cardModel.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${cardModel.valueKM.toStringAsFixed(2)} KM',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 1, color: AppColors.outline),
              
              // Donji dio (Footer): Lokacija i Rok
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Lokacija
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          cardModel.locationName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                    // Rok za prijavu
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Deadline: $formattedDeadline',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.textSecondary,
        size: 28,
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, TenderStatus status) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      // Koristimo pozadinsku boju iz tvoje ekstenzije (npr. status.badgeBg)
      color: status.badgeBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      // Koristimo labelu iz tvoje ekstenzije (npr. status.label) i prebacujemo u velika slova
      status.label.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            // Koristimo boju teksta iz tvoje ekstenzije (npr. status.badgeFg)
            color: status.badgeFg,
            fontWeight: FontWeight.w700,
            fontSize: 10,
          ),
    ),
  );
}
}
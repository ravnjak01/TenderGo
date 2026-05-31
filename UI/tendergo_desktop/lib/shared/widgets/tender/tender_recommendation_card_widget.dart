import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/tenderrecommendation_dto.dart';

/// A card widget displaying a single recommended tender.
/// Tap it to navigate to the full tender detail page.
class TenderRecommendationCard extends StatelessWidget {
  final TenderRecommendation tender;
  final VoidCallback? onTap;

  const TenderRecommendationCard({
    super.key,
    required this.tender,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUrgent = tender.daysUntilDeadline <= 3;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        // Smanjen horizontalni margin na mobilnim uređajima da dobijemo više prostora sa strana
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Thumbnail (if available) ---
            if (tender.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Image.network(
                  tender.thumbnailUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12), // Blago smanjen padding za više prostora
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Match score badge + Category ---
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _MatchBadge(score: tender.similarityScore),
                      if (tender.category != null)
                        Chip(
                          label: Text(
                            tender.category!,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // --- Title ---
                  Text(
                    tender.title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // --- Description ---
                  if (tender.description != null && tender.description!.isNotEmpty)
                    Text(
                      tender.description!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 10),
                  _RecommendationExplanation(tender: tender),
                  const SizedBox(height: 12),

                  // --- POPRAVLJEN FOOTER: Koristi Wrap umjesto Row ---
                  // Wrap automatski prebacuje element u novi red ako nema mjesta na telefonu
                  Wrap(
                    spacing: 12,    // Razmak između elemenata horizontalno
                    runSpacing: 6,   // Razmak ako se prebaci u novi red
                    alignment: WrapAlignment.start,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Budget
                      _InfoChip(
                        icon: Icons.attach_money,
                        label: tender.budgetFormatted,
                        color: Colors.green,
                      ),
                      // Location
                      if (tender.locationName != null)
                        _InfoChip(
                          icon: Icons.location_on_outlined,
                          label: tender.locationName!,
                          color: Colors.blue,
                        ),
                      // Deadline
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: isUrgent
                            ? '${tender.daysUntilDeadline}d left!'
                            : '${tender.daysUntilDeadline}d left',
                        color: isUrgent ? Colors.red : Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// Sub-widgets
// ----------------------------------------------------------------

class _RecommendationExplanation extends StatelessWidget {
  final TenderRecommendation tender;

  const _RecommendationExplanation({required this.tender});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final signals = tender.recommendationSignals
        .map((signal) => signal.trim())
        .where((signal) => signal.isNotEmpty)
        .toSet()
        .take(4)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_alt_outlined,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 5),
              Text(
                'Why recommended',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          
          // Glavni tekst objašnjenja - maknut maxLines da se tekst na mobitelu 
          // cjelovito prikaže i prebaci u nove redove umjesto da se odsječe
          Text(
            tender.explanationText,
            style: theme.textTheme.bodySmall,
          ),
          
          if (signals.isNotEmpty) ...[
            const SizedBox(height: 8),
            
            // Dinamički prikaz balončića ovisno o širini ekrana
            LayoutBuilder(
              builder: (context, constraints) {
                // Ako je širina manja od npr. 340px (tipično unutar mobilne kartice),
                // slažemo balončiće vertikalno kako bi tekst stao u potpunosti
                final isMobileLayout = constraints.maxWidth < 340;

                if (isMobileLayout) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: signals.map((signal) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: _SignalChip(label: signal, isMobile: true),
                      );
                    }).toList(),
                  );
                }

                // Ako ima dovoljno mjesta (Desktop grid), ostaje horizontalni Wrap
                return Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: signals
                      .map((signal) => _SignalChip(label: signal, isMobile: false))
                      .toList(),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  final String label;
  final bool isMobile;

  const _SignalChip({
    required this.label,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      // Ako je na mobitelu, balončić zauzima punu širinu i dopušta tekstu da ode u novi red
      width: isMobile ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.72),
        borderRadius: BorderRadius.circular(12), // Malo blaži radijus za višelinijski tekst
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
          height: 1.2, // Bolji prored za tekst koji se prelomi
        ),
        // Na mobitelu gasimo maxLines i elipsu da se vidi CIJELI tekst (npr. "Similar to locations you viewed...")
        maxLines: isMobile ? null : 1,
        overflow: isMobile ? TextOverflow.visible : TextOverflow.ellipsis,
      ),
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final double score;

  const _MatchBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final percent = (score * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _badgeColor(score),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent% match',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _badgeColor(double score) {
    if (score >= 0.75) return Colors.green;
    if (score >= 0.50) return Colors.orange;
    return Colors.grey;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Dodan Flexible i TextOverflow kako bi unutar Wrap-a dugačka lokacija (npr. "Banja Luka") 
    // elegantno dobila tri tačke ako je ekran kritično uzak
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11, 
              color: color, 
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
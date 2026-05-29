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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- Match score badge + Category ---
                  Row(
                    children: [
                      _MatchBadge(score: tender.similarityScore),
                      const SizedBox(width: 8),
                      if (tender.category != null)
                        Flexible(
                          child: Chip(
                            label: Text(tender.category!,
                                style: const TextStyle(fontSize: 11)),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                          ),
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
                  const SizedBox(height: 10),

                  // --- Footer: budget | location | deadline ---
                  Row(
                    children: [
                      // Budget
                      _InfoChip(
                        icon: Icons.attach_money,
                        label: tender.budgetFormatted,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),

                      // Location
                      if (tender.locationName != null)
                        Flexible(
                          child: _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: tender.locationName!,
                            color: Colors.blue,
                          ),
                        ),
                      const Spacer(),

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
          Text(
            tender.explanationText,
            style: theme.textTheme.bodySmall,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          if (signals.isNotEmpty) ...[
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: signals
                  .map(
                    (signal) => _SignalChip(label: signal),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SignalChip extends StatelessWidget {
  final String label;

  const _SignalChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.72),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Green badge showing the match percentage
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

/// Small icon + label row
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

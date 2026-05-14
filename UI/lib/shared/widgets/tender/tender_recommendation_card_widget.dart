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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Thumbnail (if available) ---
            if (tender.thumbnailUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  tender.thumbnailUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
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
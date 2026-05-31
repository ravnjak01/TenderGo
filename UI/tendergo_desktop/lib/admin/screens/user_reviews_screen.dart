import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/review_dto.dart';
import 'package:tendergo/shared/services/user_service.dart';

class UserReviewsScreen extends StatelessWidget {
  final String userId;
  final UserService userService;
  final String userName; // Prosljeđujemo ime da ga prikažemo u AppBaru

  const UserReviewsScreen({
    super.key,
    required this.userId,
    required this.userService,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reviews for $userName'),
        leading: const CustomBackButton(),
      ),
      body: FutureBuilder<List<ReviewDto>>(
        future: userService.getUserReviews(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load reviews.'));
          }

          final reviews = snapshot.data ?? [];

          if (reviews.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No reviews yet.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reviews.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = reviews[index];
              return _buildReviewCard(context, review);
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewDto review) {
    final formattedDate = DateFormat('dd.MM.yyyy').format(review.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Red sa nazivom tendera i ocjenom
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tender:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    ),
                    Text(
                      review.tenderTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Zvjezdica i ocjena (Score)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.amber[900],
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.outline),
          ),
          // Autor recenzije i datum
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'By: ${review.reviewerName}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                formattedDate,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Komentar recenzije
          Text(
            (review.comment ?? '').trim().isEmpty 
                ? 'No comment left.' 
                : review.comment!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: (review.comment ?? '').trim().isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                  fontStyle: (review.comment ?? '').trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
          ),
        ],
      ),
    );
  }
}
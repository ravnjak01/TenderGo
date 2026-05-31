import 'package:flutter/material.dart';
import 'package:tendergo/mobile/screens/user_reviews_screen.dart';
import 'package:tendergo/mobile/screens/user_tenders.dart';
import 'package:tendergo/shared/core/actions/back_button.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/core/utils/extensions/user_initials_extension.dart';
import 'package:tendergo/shared/models/dto/user_public_dto.dart';
import 'package:tendergo/shared/services/tender_service.dart';
import 'package:tendergo/shared/services/user_service.dart';

class UserProfilePublicScreen extends StatelessWidget {
  final String userId;
  final UserService userService;
  final TenderService tenderService;

  const UserProfilePublicScreen({
    super.key,
    required this.userId,
    required this.userService,
    required this.tenderService,
  });

  String _initials(UserPublicDto user) {
    return user.initials;
  }

  Widget _buildAvatarWidget(BuildContext context, UserPublicDto user) {
    final imageUrl = user.profileImageUrl;

    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      return Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
        child: ClipOval(
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (_, _, _) => _buildInitialsCircle(context, user),
          ),
        ),
      );
    }

    return _buildInitialsCircle(context, user);
  }

  Widget _buildInitialsCircle(BuildContext context, UserPublicDto user) {
    return CircleAvatar(
      radius: 44,
      backgroundColor: AppColors.primary.withValues(alpha: 0.14),
      child: Text(
        _initials(user),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }

  Widget _buildStatTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outline),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context)
                      .textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userId.trim().isEmpty) {
      return const Scaffold(body: Center(child: Text('Missing user ID.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('User Profile'),
        leading: const CustomBackButton(),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: FutureBuilder<UserPublicDto>(
        future: userService.getUser(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load user profile.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('User not found.'));
          }

          final user = snapshot.data!;
          final displayName =
              user.fullName.trim().isEmpty ? 'TenderGo User' : user.fullName;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(), // Dodana iOS/Android fizika
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            child: Column(
              children: [
                _buildAvatarWidget(context, user),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        user.location.trim().isEmpty
                            ? 'Location not specified'
                            : user.location.trim(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outline),
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stats',
                        style: Theme.of(context)
                            .textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _buildStatTile(
                        context,
                        icon: Icons.star_rounded,
                        label: 'Rating',
                        value: user.rating.toStringAsFixed(1),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserReviewsScreen(
                                userId: userId,
                                userService: userService,
                                userName: displayName,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildStatTile(
                        context,
                        icon: Icons.assignment_outlined,
                        label: 'Tenders',
                        value: user.tenderCount.toString(),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserTendersScreen(
                                userId: userId,
                                userName: displayName,
                                tenderService: tenderService,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildStatTile(
                        context,
                        icon: Icons.gavel_rounded,
                        label: 'Bids',
                        value: user.bidsCount.toString(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:tendergo/admin/widgets/common/app_action_tile.dart';
import 'package:tendergo/admin/widgets/common/app_badge.dart';
import 'package:tendergo/admin/widgets/user_profile_cards.dart';
import 'package:tendergo/admin/widgets/user_profile_header.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/core/utils/extensions/string_extensions.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/shared/models/dto/bid_dto.dart';
import 'package:tendergo/shared/models/dto/tender_dto.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';
import 'package:tendergo/shared/routes/routes.dart';


//sljedece praviti klik na my bids i tenders prikazat listu bidova i tendera koje je korisnik kreirao, a ne sve bidove i tendere

class UserProfileMobile extends StatelessWidget {
  const UserProfileMobile({
    super.key,
    required this.user,
    required this.bids,
    required this.tenders,
    required this.onChangePassword,
    required this.onLogout,
  });

  final UserDto user;
  final List<BidDto> bids;
  final List<TenderDto> tenders;
  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: UserProfileHeader(
            user: user,
            onBack: () => Navigator.pop(context),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              UserProfileRolesSection(roles: user.roles),
              const SizedBox(height: 16),
              UserProfileCards(user: user),
              const SizedBox(height: 16),
              UserProfileStatsCard(
                bidsCount: bids.length,
                tendersCount: tenders.length,
                onBidsTap: () => Navigator.of(context).pushNamed(AppRoutes.myBids),
                onTendersTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.myTenders),
              ),
              const SizedBox(height: 32),
              ActionTile(
                icon: Icons.lock_outline_rounded,
                label: 'Change Password',
                onTap: onChangePassword,
              ),
              const SizedBox(height: 10),
              ActionTile(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                destructive: true,
                onTap: onLogout,
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class UserProfileDesktop extends StatelessWidget {
  const UserProfileDesktop({super.key, required this.user});

  final UserDto user;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: UserProfileHeader(
                user: user,
                onBack: () => Navigator.pop(context),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(children: [UserProfileCards(user: user)]),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 2,
                      child: Card(
                        elevation: 0,
                        color: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: const BorderSide(color: AppColors.outline),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Roles',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 12),
                              UserProfileRolesSection(roles: user.roles),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UserProfileRolesSection extends StatelessWidget {
  const UserProfileRolesSection({super.key, required this.roles});

  final List<String> roles;

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: roles.map((r) => AppBadge(label: r.toRoleLabel())).toList(),
    );
  }
}

class UserProfileStatsCard extends StatelessWidget {
  const UserProfileStatsCard({
    super.key,
    required this.bidsCount,
    required this.tendersCount,
    this.onBidsTap,
    this.onTendersTap,
  });

  final int bidsCount;
  final int tendersCount;
  final VoidCallback? onBidsTap;
  final VoidCallback? onTendersTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: UserProfileStatTile(
                icon: Icons.gavel_rounded,
                label: 'My Bids',
                value: bidsCount.toString(),
                onTap: onBidsTap,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: UserProfileStatTile(
                icon: Icons.assignment_outlined,
                label: 'My Tenders',
                value: tendersCount.toString(),
                onTap: onTendersTap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//zadnje implementirao klikove na my bids i my tenders, 
class UserProfileStatTile extends StatelessWidget {
  const UserProfileStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: onTap != null ? AppColors.primary : AppColors.outline,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const Spacer(),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Click for more',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

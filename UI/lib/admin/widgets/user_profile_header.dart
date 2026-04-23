import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/models/dto/auth_dto.dart';
import 'package:tendergo/admin/widgets/common/app_icon.dart';

class UserProfileHeader extends StatelessWidget {
  final UserDto user;
  final VoidCallback? onBack;

  const UserProfileHeader({
    super.key,
    required this.user,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Top bar
          Row(
            children: [
              AppIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack ?? () => Navigator.maybePop(context),
              ),
              const Spacer(),
              Text(
                'Profile',
                style: textTheme.titleMedium,
              ),
              
            ],
          ),
          const SizedBox(height: 28),
          
          // Avatar section
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.infoSurface,
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  UserDto.getInitials(user),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              // Online status indicator
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Name and Email
          Text(
            user.username,
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';
import 'package:tendergo/shared/core/utils/extensions/user_initials_extension.dart';
import 'package:tendergo/shared/models/dto/user_dto.dart';

class UserAvatarWidget extends StatelessWidget {
  final UserDto? user;
  final VoidCallback onTap;
  final double size;
  final Color backgroundColor;
  final Color textColor;

  const UserAvatarWidget({
    super.key,
    required this.user,
    required this.onTap,
    this.size = 38,
    this.backgroundColor = AppColors.infoSurface,
    this.textColor = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = user?.profileImageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Image.network(
                imageUrl,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
              )
            : _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Center(
      child: Text(
        user != null ? user!.initials : '',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.37,
        ),
      ),
    );
  }
}

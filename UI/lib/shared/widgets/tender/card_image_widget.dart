import 'package:flutter/material.dart';
import 'package:tendergo/shared/models/dto/category_dto.dart';

class TenderCardImage extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final Widget? badge; 
  final CategoryTheme theme;

  const TenderCardImage({
    super.key, 
    this.imageUrl, 
    this.height = 140, 
    this.badge, 
    required this.theme
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImageOrPlaceholder(),
          if (badge != null)
            Positioned(top: 10, left: 10, child: badge!),
        ],
      ),
    );
  }

  Widget _buildImageOrPlaceholder() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _Placeholder(theme: theme),
      );
    }
    return _Placeholder(theme: theme);
  }

}
  class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.theme});
  final CategoryTheme theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: theme.bg,
      alignment: Alignment.center,
      child: Icon(theme.icon, size: 48, color: theme.bg.withOpacity(1).withAlpha(80)),
    );
  }
}
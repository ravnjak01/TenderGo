import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';

class TenderImageGallery extends StatefulWidget {
  const TenderImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 260,
    this.width = double.infinity,
  });

  final List<String> imageUrls;
  final double height;
  final double width;

  @override
  State<TenderImageGallery> createState() => _TenderImageGalleryState();
}

class _TenderImageGalleryState extends State<TenderImageGallery> {
  int _activeIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.height,
            width: widget.width,
            child: PageView.builder(
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _activeIndex = i),
              itemBuilder: (context, index) => Image.network(
                widget.imageUrls[index],
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.broken_image, color: AppColors.textDisabled),
                ),
              ),
            ),
          ),
        ),
        if (widget.imageUrls.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.imageUrls.length,
              (index) => Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _activeIndex == index ? AppColors.primary : AppColors.textDisabled,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

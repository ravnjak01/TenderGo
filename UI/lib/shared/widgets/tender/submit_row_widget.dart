import 'package:flutter/material.dart';
import 'package:tendergo/shared/core/theme/app_theme.dart';

class TenderSubmitRow extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmitTender;
  final bool useCompactStyle;
  final bool fullWidthOnMobile;
  final String publishTenderLabel;

  const TenderSubmitRow({
    super.key,
    required this.isLoading,
    required this.onSubmitTender,
    this.useCompactStyle = false,
    this.fullWidthOnMobile = true,
    this.publishTenderLabel = 'Publish Tender',
  });

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 600;

    // Keep desktop dimensions while allowing stacked full-width buttons on mobile.
    final double publishWidth = useCompactStyle ? 154 : 180;
    final double buttonHeight = useCompactStyle ? 46 : (isMobile ? 48 : 52);
    final bool stretchButtons = isMobile && fullWidthOnMobile;

    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        SizedBox(
          width: stretchButtons ? double.infinity : publishWidth,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onSubmitTender,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _ButtonContent(
              isLoading: isLoading,
              icon: Icons.publish_rounded,
              label: publishTenderLabel,
              isPrimary: true,
              isCompact: useCompactStyle,
            ),
          ),
        ),
      ],
    );
  }
}

class _ButtonContent extends StatelessWidget {
  final bool isLoading;
  final IconData icon;
  final String label;
  final bool isPrimary;
  final bool isCompact;

  const _ButtonContent({
    required this.isLoading,
    required this.icon,
    required this.label,
    required this.isPrimary,
    required this.isCompact,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: isPrimary ? Colors.white : AppColors.primary,
              ),
            )
          : FittedBox(
              key: ValueKey(label),
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isPrimary ? Colors.white : AppColors.primary,
                    size: isCompact ? 17 : 19,
                  ),
                  SizedBox(width: isCompact ? 6 : 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isPrimary ? Colors.white : AppColors.primary,
                      fontSize: isCompact ? 13 : 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

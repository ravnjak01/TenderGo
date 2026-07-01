import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor,
    this.iconColor,
  });

  bool _isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 800; // breakpoint (tablet/desktop)
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = _isDesktop(context);

    final double iconSize = isDesktop ? 22 : 18;
    final double buttonSize = isDesktop ? 44 : 36;

    return MouseRegion(
  cursor: SystemMouseCursors.click,
  child: SizedBox( 
    width: buttonSize,
    height: buttonSize,
    child: Material(
      color: backgroundColor ?? theme.colorScheme.surface.withValues(alpha: isDesktop ? 0.8 : 0.6),
      shape: const CircleBorder(), 
      clipBehavior: Clip.antiAlias, 
      child: InkWell(
        onTap: onPressed ?? () => Navigator.of(context).maybePop(),
        child: Center(
          child: Icon(
            Icons.arrow_back_ios_new,
            size: iconSize,
            color: iconColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ),
    ),
  ),
);
  }
}
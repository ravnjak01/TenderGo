import 'package:flutter/material.dart';

class FadeInWrapper extends StatefulWidget {
  final Widget child;
  final int durationMs;

  const FadeInWrapper({
    super.key,
    required this.child,
    this.durationMs = 540, // Tvojih 540ms kao default
  });

  @override
  State<FadeInWrapper> createState() => _FadeInWrapperState();
}

class _FadeInWrapperState extends State<FadeInWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _aniCtrl;
  late final Animation<double> _fadeAni;

  @override
  void initState() {
    super.initState();
    _aniCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );

    _fadeAni = CurvedAnimation(
      parent: _aniCtrl,
      curve: Curves.easeOut,
    );

    _aniCtrl.forward();
  }

  @override
  void dispose() {
    _aniCtrl.dispose(); // Važno: oslobađa memoriju na mobitelu
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAni,
      child: widget.child,
    );
  }
}
import 'package:flutter/material.dart';

class AuthScaffold extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry cardPadding;

  const AuthScaffold({
    super.key,
    required this.child,
    this.maxWidth = 400,
    this.cardPadding = const EdgeInsets.all(30),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A3A6B), Color(0xFF1E4DB7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxWidth),
              padding: cardPadding,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 20,
                    color: Colors.black26,
                    offset: Offset(0, 10),
                  )
                ],
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

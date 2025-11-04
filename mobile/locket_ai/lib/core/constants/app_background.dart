import 'package:flutter/material.dart';
import 'package:locket_ai/core/constants/background.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: AnimatedGradientBackground()),
        child,
      ],
    );
  }
}
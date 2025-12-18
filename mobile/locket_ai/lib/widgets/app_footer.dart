import 'package:flutter/material.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:locket_ai/widgets/gradient_icon.dart';

class AppFooter extends StatelessWidget {
  final VoidCallback onLeftTap;
  final VoidCallback onButtonTap;
  final VoidCallback onRightTap;
  final VoidCallback? onMenuTap; // Optional menu handler

  const AppFooter({
    super.key,
    required this.onLeftTap,
    required this.onButtonTap,
    required this.onRightTap,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 45),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onLeftTap,
            child: const GradientIcon(icon: Icons.apps_rounded, size: 40),
          ),
          GestureDetector(
            onTap: onButtonTap,
            child: Container(
              height: 60,
              width: 60,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: instagramGradient,
              ),
              child: Center(
                child: Container(
                  height: 52,
                  width: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onMenuTap ?? onRightTap,
            child: const GradientIcon(icon: Icons.more_horiz_outlined, size: 40),
          ),
        ],
      ),
    );
  }
}

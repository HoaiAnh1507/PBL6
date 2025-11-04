import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/gradient_icon.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback onLeftTap;
  final Widget friendsSection;
  final VoidCallback onRightTap;

  const AppHeader({
    Key? key,
    required this.onLeftTap,
    required this.friendsSection,
    required this.onRightTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: onLeftTap,
          child: const GradientCircleIcon(
            icon: Icons.account_circle_outlined,
            size: 30,
          ),
        ),
        friendsSection,
        GestureDetector(
          onTap: onRightTap,
          child: const GradientCircleIcon(
            icon: Icons.maps_ugc_outlined,
            size: 30,
          ),
        ),
      ],
    );
  }
}

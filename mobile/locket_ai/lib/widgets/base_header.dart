import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/app_header.dart';
import 'package:locket_ai/widgets/friend_button.dart';

class BaseHeader extends StatelessWidget {
  final PageController horizontalController;
  final int count;
  final String label;
  final VoidCallback onTap;

  const BaseHeader({
    Key? key,
    required this.horizontalController,
    required this.count,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  void _navigateToPage(int index) {
    horizontalController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppHeader(
      onLeftTap: () => _navigateToPage(0),
      onRightTap: () => _navigateToPage(2),
      friendsSection: FriendsButton(count: count, label: label, onTap: onTap),
    );
  }
}

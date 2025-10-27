import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/app_footer.dart';

class BaseFooter extends StatelessWidget {
  final PageController horizontalController;

  const BaseFooter({
    super.key,
    required this.horizontalController,
  });

  void _navigateToPage(int index) {
    horizontalController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFooter(
      onLeftTap: () => _navigateToPage(0),
      onButtonTap: () => _navigateToPage(1),
      onRightTap: () => _navigateToPage(2),
    );
  }
}

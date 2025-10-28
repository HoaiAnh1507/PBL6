import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/app_footer.dart';

class BaseFooter extends StatelessWidget {
  final PageController verticalController;

  const BaseFooter({
    super.key,
    required this.verticalController,
  });

  void _navigateToPage(int index) {
    verticalController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppFooter(
      onLeftTap: () => _navigateToPage(0),
      onButtonTap: () => _navigateToPage(0),
      onRightTap: () => _navigateToPage(0),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:locket_ai/widgets/app_footer.dart';

class BaseFooter extends StatelessWidget {
  final PageController verticalController;
  final TextEditingController messageController;
  final VoidCallback onSend;

  const BaseFooter({
    super.key,
    required this.verticalController,
    required this.messageController,
    required this.onSend,
  });

  void _navigateToPage(int index) {
    verticalController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: 
      // Column(
      //   mainAxisSize: MainAxisSize.min,
        // children: [
        //   MessageBar(controller: messageController, onSend: onSend),
        //   const SizedBox(height: 10),
          AppFooter(
            onLeftTap: () => _navigateToPage(0),
            onButtonTap: () => _navigateToPage(0),
            onRightTap: () => _navigateToPage(0),
          ),
        // ],
      // ),
    );
  }
}
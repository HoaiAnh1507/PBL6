import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  const CustomButton({Key? key, required this.onTap, required this.child, this.padding = const EdgeInsets.all(12)}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(padding: padding, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)), child: child),
    );
  }
}

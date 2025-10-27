import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/core/constants/colors.dart';

class FriendsButton extends StatelessWidget {
  final int count;
  final String label;
  final VoidCallback onTap;

  const FriendsButton({
    super.key,
    required this.count,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(79, 76, 76, 0.298),
          borderRadius: BorderRadius.circular(40),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => instagramGradient.createShader(bounds),
              child: const Icon(
                Icons.group_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count.toString(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

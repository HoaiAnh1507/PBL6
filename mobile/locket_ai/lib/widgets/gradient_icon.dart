import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class GradientCircleIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const GradientCircleIcon({
    super.key,
    required this.icon,
    this.size = 26,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        width: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: instagramGradient,
        ),
        child: Center(
          child: Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(0.3),
            ),
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return instagramGradient.createShader(bounds);
              },
              child: Icon(
                icon,
                size: size,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final VoidCallback? onTap;

  const GradientIcon({
    super.key,
    required this.icon,
    this.size = 28,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return instagramGradient.createShader(bounds);
      },
      child: Icon(
        icon,
        size: size,
        color: Colors.white,
      ),
    );
  }
}

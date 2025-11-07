import 'package:flutter/material.dart';
import 'package:locket_ai/core/constants/colors.dart';

class WaveEffect extends StatefulWidget {
  final double size;
  final Duration duration;

  const WaveEffect({
    Key? key,
    this.size = 90,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<WaveEffect> createState() => _WaveEffectState();
}

class _WaveEffectState extends State<WaveEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)..forward();
    _scale = Tween<double>(begin: 1.0, end: 2.5).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _opacity = Tween<double>(begin: 0.4, end: 0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Opacity(
          opacity: _opacity.value,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: instagramGradient,
            ),
          ),
        ),
      ),
    );
  }
}

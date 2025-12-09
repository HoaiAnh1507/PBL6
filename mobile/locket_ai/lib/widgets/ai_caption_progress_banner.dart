import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/colors.dart';
import '../viewmodels/ai_caption_viewmodel.dart';

/// A progress banner widget that displays AI caption generation status
/// Styled to match the app's gradient aesthetic
class AICaptionProgressBanner extends StatelessWidget {
  final VoidCallback onTap;
  final CaptionJobStatus status;

  const AICaptionProgressBanner({
    super.key,
    required this.onTap,
    required this.status,
  });

  String get _titleText {
    switch (status) {
      case CaptionJobStatus.processing:
        return 'AI is creating your caption...';
      case CaptionJobStatus.completed:
        return 'Caption ready!';
      case CaptionJobStatus.failed:
        return 'AI caption failed';
    }
  }

  String get _subtitleText {
    switch (status) {
      case CaptionJobStatus.processing:
        return 'Tap to view progress';
      case CaptionJobStatus.completed:
        return 'Tap to view and post';
      case CaptionJobStatus.failed:
        return 'Tap to retry or continue';
    }
  }

  IconData get _icon {
    switch (status) {
      case CaptionJobStatus.processing:
        return Icons.arrow_forward_ios;
      case CaptionJobStatus.completed:
        return Icons.check_circle_outline;
      case CaptionJobStatus.failed:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: instagramGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status indicator
            if (status == CaptionJobStatus.processing)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                _icon,
                color: Colors.white,
                size: 20,
              ),
            const SizedBox(width: 12),
            
            // Progress text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titleText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _subtitleText,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow icon
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.9),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

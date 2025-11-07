import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../../core/constants/colors.dart';
import '../../widgets/gradient_icon.dart';

class CapturePreviewPage extends StatefulWidget {
  final String imagePath;
  final bool isVideo;
  final Function(String caption) onPost;

  const CapturePreviewPage({
    super.key,
    required this.imagePath,
    this.isVideo = false,
    required this.onPost,
  });

  @override
  State<CapturePreviewPage> createState() => _CapturePreviewPageState();
}

class _CapturePreviewPageState extends State<CapturePreviewPage> {
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocusNode = FocusNode();
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  // Demo AI caption generation state
  bool _aiGenerating = false;
  String _aiPhaseText = '';
  Timer? _typingTimer;
  final String _aiTargetCaption = 'This is AI generated caption';
  int _typingIndex = 0;

  String _wrapPerLine(String text, int maxChars) {
    final lines = text.split('\n');
    final wrapped = <String>[];
    for (final line in lines) {
      if (line.length <= maxChars) {
        wrapped.add(line);
      } else {
        for (int i = 0; i < line.length; i += maxChars) {
          final end = (i + maxChars) > line.length ? line.length : (i + maxChars);
          wrapped.add(line.substring(i, end));
        }
      }
    }
    return wrapped.join('\n');
  }

  @override
  void initState() {
    super.initState();
    if (widget.isVideo) {
      _videoController = VideoPlayerController.file(File(widget.imagePath))
        ..initialize().then((_) {
          setState(() => _isVideoInitialized = true);
          _videoController!.setLooping(true);
          _videoController!.play();
        });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocusNode.dispose();
    _videoController?.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startAIDemo() async {
    if (_aiGenerating) return;
    setState(() {
      _aiGenerating = true;
      _aiPhaseText = 'AI is analyzing...';
      _typingIndex = 0;
    });

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _aiPhaseText = 'AI is thinking...');

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _aiPhaseText = 'AI is generating...');

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() {
      _aiPhaseText = '';
      _captionController.text = '';
      _typingIndex = 0;
    });

    _typingTimer?.cancel();
    _typingTimer = Timer.periodic(const Duration(milliseconds: 55), (t) {
      if (_typingIndex < _aiTargetCaption.length) {
        _typingIndex++;
        _captionController.text = _aiTargetCaption.substring(0, _typingIndex);
        setState(() {});
      } else {
        t.cancel();
        _typingTimer = null;
        setState(() {
          _aiGenerating = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: MediaQuery.removeViewInsets(
          removeBottom: true,
          context: context,
          child: Stack(
          children: [
        Positioned(
          top: 60,
          left: 30,
          right: 30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Text(
                'Send to...',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  try {
                    File(widget.imagePath);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File đã được lưu (demo)')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi tải file: $e')),
                    );
                  }
                },
                child: const Icon(Icons.download, color: Colors.white, size: 28),
              ),
            ],
          ),
        ),

        // Ảnh hoặc video preview
        Positioned(
          top: 130,
          left: 7,
          right: 7,
          child: SizedBox(
            width: size,
            height: size,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Stack(
                children: [
                  // Media base
                  Positioned.fill(
                    child: widget.isVideo
                        ? (_isVideoInitialized
                            ? GestureDetector(
                                onTap: () {
                                  if (_videoController!.value.isPlaying) {
                                    _videoController!.pause();
                                  } else {
                                    _videoController!.play();
                                  }
                                  setState(() {});
                                },
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController!.value.size.width,
                                    height: _videoController!.value.size.height,
                                    child: VideoPlayer(_videoController!),
                                  ),
                                ),
                              )
                            : const Center(child: CircularProgressIndicator()))
                        : Image.file(
                            File(widget.imagePath),
                            fit: BoxFit.cover,
                            width: size,
                            height: size,
                          ),
                  ),
                  // Play icon overlay when video paused
                  if (widget.isVideo &&
                      _isVideoInitialized &&
                      !_videoController!.value.isPlaying)
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        color: Colors.white,
                        size: 80,
                      ),
                    ),
                  // Caption overlay on media
                  Positioned(
                    left: 15,
                    right: 15,
                    bottom: 15,
                    child: Builder(
                      builder: (context) {
                        final TextStyle style = GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        );

                        final String displayText = _aiGenerating && _aiPhaseText.isNotEmpty
                            ? _aiPhaseText
                            : (_captionController.text.isEmpty
                                ? 'Share your thoughts...'
                                : _captionController.text);

                        // Tính độ rộng theo nội dung
                        final lines = displayText.split('\n');
                        double longestWidth = 0;
                        int longestLen = 0;
                        for (final l in lines) {
                          final tp = TextPainter(
                            text: TextSpan(text: l.isEmpty ? ' ' : l, style: style),
                            maxLines: 1,
                            textDirection: Directionality.of(context),
                            textScaler: MediaQuery.textScalerOf(context),
                          )..layout();
                          if (tp.width > longestWidth) longestWidth = tp.width;
                          if (l.length > longestLen) longestLen = l.length;
                        }

                        final double maxChipWidth = size - 30;
                        final double horizontalPadding = 15;
                        final double verticalPadding = 10;
                        final double innerHorizontalPadding = 12;
                        final double slack = innerHorizontalPadding * 2 + 12;
                        final double measuredWidth =
                            longestWidth.ceilToDouble() + horizontalPadding * 2 + slack;

                        final bool contentHasNewline = displayText.contains('\n');
                        final bool isSingleLineContent = !contentHasNewline && measuredWidth <= maxChipWidth;
                        final double chipWidth = isSingleLineContent
                            ? (measuredWidth.clamp(120.0, maxChipWidth) as double)
                            : maxChipWidth;

                        final double chipRadius = isSingleLineContent
                            ? ((18.0 + (longestLen / 35.0) * 12).clamp(18.0, 30.0) as double)
                            : 30.0;

                        // Lift only the caption chip when keyboard opens and TextField has focus
                        final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
                        final bool shouldLift = keyboardInset > 0 && _captionFocusNode.hasFocus;
                        final double lift = shouldLift ? math.min(keyboardInset, 220) : 0.0;

                        return Center(
                          child: Transform.translate(
                            offset: Offset(0, -lift),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              width: chipWidth,
                              padding: EdgeInsets.symmetric(
                                  horizontal: horizontalPadding, vertical: verticalPadding),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(chipRadius),
                              ),
                              child: (_aiGenerating && _aiPhaseText.isNotEmpty)
                                  ? AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 250),
                                    child: Text(
                                      _aiPhaseText,
                                      key: ValueKey(_aiPhaseText),
                                      textAlign: TextAlign.center,
                                      style: style,
                                      maxLines: 1,
                                    ),
                                  )
                                : TextField(
                                    controller: _captionController,
                                    focusNode: _captionFocusNode,
                                    readOnly: _aiGenerating,
                                    textAlign: isSingleLineContent ? TextAlign.left : TextAlign.center,
                                    // Nếu nội dung thực sự chỉ 1 dòng -> ép 1 dòng để tránh wrap sớm; ngược lại tối đa 3 dòng
                                    maxLines: (_captionController.text.isEmpty || isSingleLineContent) ? 1 : 3,
                                    minLines: 1,
                                    style: style,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      // Đồng bộ với phần đo chiều rộng
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                      hintText: 'Share your thoughts...',
                                      hintStyle: GoogleFonts.poppins(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.none,
                                      ),
                                    ),
                                    onChanged: (value) {
                                      // Bỏ phân dòng theo số ký tự, để wrap tự nhiên theo pixel
                                      setState(() {});
                                    },
                                    textInputAction: TextInputAction.done,
                                  ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Ô nhập caption đã chuyển thành overlay trong phần preview

        // Các nút bên dưới
        Positioned(
          bottom: 180,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const GradientIcon(icon: Icons.cancel_outlined, size: 30),
              ),
              GestureDetector(
                onTap: () {
                  widget.onPost(_captionController.text);
                  Navigator.pop(context);
                },
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: instagramGradient,
                  ),
                  child: const Center(
                    child: Icon(Icons.send, color: Colors.white, size: 40),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _startAIDemo,
                child: const GradientIcon(icon: Icons.auto_fix_high, size: 30),
              ),
            ],
          ),
        ),
          ],
        )),
    );
  }
}

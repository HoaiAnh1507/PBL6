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
  // AI cancellation and generation tracking
  int _aiGenerationId = 0;
  bool _aiCancelRequested = false;

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

  Future<void> _typeText(String text, void Function(String) onTyped,
      {int speedMs = 55, int dotMs = 360, int? genId}) async {
    for (int i = 1; i <= text.length; i++) {
      if ((genId != null && genId != _aiGenerationId) || _aiCancelRequested) return;
      onTyped(text.substring(0, i));
      if (mounted) setState(() {});
      final char = text[i - 1];
      final delay = (char == '.') ? dotMs : speedMs;
      await Future.delayed(Duration(milliseconds: delay));
      if ((genId != null && genId != _aiGenerationId) || _aiCancelRequested) return;
    }
  }

  Future<void> _eraseText(String text, void Function(String) onTyped,
      {int speedMs = 35, int? genId}) async {
    for (int i = text.length - 1; i >= 0; i--) {
      if ((genId != null && genId != _aiGenerationId) || _aiCancelRequested) return;
      onTyped(text.substring(0, i));
      if (mounted) setState(() {});
      await Future.delayed(Duration(milliseconds: speedMs));
      if ((genId != null && genId != _aiGenerationId) || _aiCancelRequested) return;
    }
  }

  // ------------------- Mood Picker and Backend -------------------
  static const List<String> _moodsEn = [
    'happy',
    'sad',
    'excited',
    'calm',
    'anxious',
    'angry',
    'tired',
    'energetic',
    'lonely',
    'grateful',
    'stressed',
    'relaxed',
    'confident',
    'bored',
    'curious',
    'hopeful',
    'frustrated',
    'proud',
    'overwhelmed',
    'motivated',
  ];

  // Icon mapping for each mood (safe, widely available Material icons)
  static final Map<String, IconData> _moodIcons = {
    'happy': Icons.sentiment_satisfied,
    'sad': Icons.sentiment_dissatisfied,
    'excited': Icons.flash_on,
    'calm': Icons.self_improvement,
    'anxious': Icons.priority_high,
    'angry': Icons.mood_bad,
    'tired': Icons.bedtime,
    'energetic': Icons.fitness_center,
    'lonely': Icons.person_outline,
    'grateful': Icons.favorite,
    'stressed': Icons.warning,
    'relaxed': Icons.spa,
    'confident': Icons.verified,
    'bored': Icons.sentiment_neutral,
    'curious': Icons.search,
    'hopeful': Icons.auto_awesome,
    'frustrated': Icons.sentiment_dissatisfied,
    'proud': Icons.workspace_premium,
    'overwhelmed': Icons.waves,
    'motivated': Icons.flag,
  };

  IconData _iconForMood(String mood) {
    return _moodIcons[mood.toLowerCase()] ?? Icons.sentiment_neutral;
  }

  Future<void> _sendMoodToBackend(String moodEn) async {
    // TODO: replace with real API call
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mood sent: $moodEn')),
    );
  }

  Future<void> _openMoodSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final height = MediaQuery.of(ctx).size.height * 0.33;
        final width = MediaQuery.of(ctx).size.width;
        final columns = width >= 420 ? 3 : 2;
        final aspect = columns == 2 ? 3.8 : 3.2;
        const itemStyle = TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        );
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      height: 5,
                      width: 40,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'How are you feeling?',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: aspect,
                      ),
                      itemCount: _moodsEn.length,
                      primary: false,
                      physics: const BouncingScrollPhysics(),
                      addAutomaticKeepAlives: false,
                      addSemanticIndexes: false,
                      cacheExtent: 300,
                      itemBuilder: (context, index) {
                        final mEn = _moodsEn[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx, mEn);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black54, blurRadius: 8, offset: Offset(0, 4)),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_iconForMood(mEn), color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    mEn,
                                    textAlign: TextAlign.center,
                                    style: itemStyle,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
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
        );
      },
    );

    if (selected != null) {
      await _sendMoodToBackend(selected);
      if (!mounted) return;
      _startAIDemo();
    }
  }

  void _startAIDemo() async {
    if (_aiGenerating) return;
    _typingTimer?.cancel();
    final int genId = ++_aiGenerationId;
    _aiCancelRequested = false;
    setState(() {
      _aiGenerating = true;
      _aiPhaseText = '';
    });

    await _typeText('AI is analyzing...', (s) => _aiPhaseText = s, genId: genId);
    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    await _eraseText(_aiPhaseText, (s) => _aiPhaseText = s, genId: genId);

    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    await _typeText('AI is thinking...', (s) => _aiPhaseText = s, genId: genId);
    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    await _eraseText(_aiPhaseText, (s) => _aiPhaseText = s, genId: genId);

    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    await _typeText('AI is generating...', (s) => _aiPhaseText = s, genId: genId);
    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    await _eraseText(_aiPhaseText, (s) => _aiPhaseText = s, genId: genId);

    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    _captionController.text = '';
    await _typeText(_aiTargetCaption, (s) => _captionController.text = s, genId: genId);

    if (!mounted || genId != _aiGenerationId || _aiCancelRequested) return;
    setState(() {
      _aiGenerating = false;
    });
  }

  void _cancelAIGeneration() {
    _typingTimer?.cancel();
    _aiCancelRequested = true;
    _aiGenerationId++;
    setState(() {
      _aiGenerating = false;
      _aiPhaseText = '';
    });
    _captionController.clear();
    FocusScope.of(context).unfocus();
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
                  if (_aiGenerating) return;
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
                                  if (_aiGenerating) return;
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

                        final String displayText = _aiGenerating
                            ? (_aiPhaseText.isNotEmpty
                                ? _aiPhaseText
                                : (_captionController.text.isNotEmpty
                                    ? _captionController.text
                                    : ' '))
                            : (_captionController.text.isEmpty
                                ? 'Share your thought'
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
                                  ? Text(
                                      _aiPhaseText,
                                      textAlign: TextAlign.center,
                                      style: style,
                                      maxLines: 1,
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
                                      hintText: _aiGenerating ? null : 'Share your thoughts...',
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
                onTap: () {
                  if (_aiGenerating) {
                    _cancelAIGeneration();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: const GradientIcon(icon: Icons.cancel_outlined, size: 30),
              ),
              Opacity(
                opacity: _aiGenerating ? 0.4 : 1.0,
                child: GestureDetector(
                  onTap: () {
                    if (_aiGenerating) return;
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
              ),
              Opacity(
                opacity: _aiGenerating ? 0.4 : 1.0,
                child: GestureDetector(
                  onTap: () {
                    if (_aiGenerating) return;
                    _openMoodSheet();
                  },
                  child: const GradientIcon(icon: Icons.auto_fix_high, size: 30),
                ),
              ),
            ],
          ),
        ),
          ],
        )),
    );
  }
}

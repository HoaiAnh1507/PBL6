import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:locket_ai/widgets/gradient_icon.dart';
import 'package:locket_ai/widgets/wave_effect.dart';
import '../../core/constants/background.dart';
import 'capture_overlay.dart';
import '../feed/feed_view.dart';
import '../../core/services/camera_service.dart';
import 'camera_preview.dart';

class CameraView extends StatefulWidget {
  const CameraView({Key? key}) : super(key: key);

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  late PageController _vCtrl;
  CameraController? _camCtrl;
  bool _cameraReady = false;
  List<CameraDescription> _cams = [];
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _vCtrl = PageController(initialPage: 0);
    _init();
  }

  Future<void> _init() async {
    _cams = await CameraService.available();
    if (_cams.isNotEmpty) {
      _camCtrl = CameraController(_cams.first, ResolutionPreset.high, enableAudio: false);
      await _camCtrl!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    }
  }

  @override
  void dispose() {
    _vCtrl.dispose();
    _camCtrl?.dispose();
    super.dispose();
  }

  void _onCapturePressed() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    final file = await _camCtrl!.takePicture();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CaptureOverlay(
        imagePath: file.path,
        onPost: (caption) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Đăng thành công (demo)')));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: _vCtrl,
      scrollDirection: Axis.vertical,
      children: [
        _cameraReady
            ? Stack(
                children: [
                  // Overlay gradient top
                  const Positioned.fill(child: AnimatedGradientBackground()),

                  // Header
                  Positioned(
                    top: 60,
                    left: 30,
                    right: 30,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const GradientIcon(icon: Icons.person_outline, size: 30),
                        Text(
                          "Friends",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const GradientIcon(icon: Icons.chat_bubble_outline, size: 30),
                      ],
                    ),
                  ),

                  Positioned(
                    top: 130,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.width,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: CameraPreviewWidget(controller: _camCtrl!),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Capture controls
                  Positioned(
                    bottom: 180,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const GradientIcon(icon: Icons.photo_library_outlined, size: 30),
                        GestureDetector(
                          onTapDown: (_) => setState(() => _isPressed = true),
                          onTapUp: (_) async {
                            setState(() => _isPressed = false);
                            await Future.delayed(const Duration(milliseconds: 200));
                            _onCapturePressed();
                          },
                          onTapCancel: () => setState(() => _isPressed = false),
                          child: Container(
                            height: 90,
                            width: 90,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: instagramGradient,
                            ),
                            child: Center(
                              child: AnimatedScale(
                                scale: _isPressed ? 0.85 : 1.0,
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeOut,
                                child: Container(
                                  height: 78,
                                  width: 78,
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        GestureDetector(
                          onTap: () async {
                            if (_cams.length < 2) return;
                            final currentIndex = _cams.indexOf(_camCtrl!.description);
                            final nextIndex = (currentIndex + 1) % _cams.length;
                            _camCtrl = CameraController(
                              _cams[nextIndex],
                              ResolutionPreset.high,
                              enableAudio: false,
                            );
                            await _camCtrl!.initialize();
                            if (mounted) setState(() {});
                          },
                          child: const GradientIcon(icon: Icons.flip_camera_ios, size: 30),
                        ),
                      ],
                    ),
                  ),

                  // Bottom text (History)
                  Positioned(
                    bottom: 70,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        Text(
                          "History",
                          style: GoogleFonts.poppins(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const GradientIcon(icon: Icons.expand_more),
                      ],
                    ),
                  ),
                ],
              )
            : const Center(
                child: CircularProgressIndicator(
                  color: Colors.pinkAccent,
                ),
              ),
        FeedView(
          onScrollUpAtTop: () {
            _vCtrl.animateToPage(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ],
    );
  }
}

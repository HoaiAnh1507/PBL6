import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:locket_ai/widgets/gradient_icon.dart';
import '../../core/constants/background.dart';
import 'capture_overlay.dart';
import '../feed/feed_view.dart';
import '../../core/services/camera_service.dart';
import 'camera_preview.dart';
import 'package:permission_handler/permission_handler.dart';

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
  bool _isRecording = false;
  double _recordProgress = 0.0;
  Timer? _recordTimer;
  final int _maxDuration = 15;

  @override
  void initState() {
    super.initState();
    _vCtrl = PageController(initialPage: 0);
    _init();
  }

  Future<void> _startRecording() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    try {
      await _camCtrl!.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordProgress = 0.0;
      });

      const tick = Duration(milliseconds: 100);
      _recordTimer = Timer.periodic(tick, (timer) {
        final elapsed = timer.tick * tick.inMilliseconds / 1000; // giây
        setState(() => _recordProgress = elapsed / _maxDuration);
        if (elapsed >= _maxDuration) {
          _stopRecording(); // Tự dừng khi đủ 15s
        }
      });
    } catch (e) {
      debugPrint("Error starting video: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (_camCtrl == null || !_isRecording) return;
    try {
      _recordTimer?.cancel();
      _recordTimer = null;

      final file = await _camCtrl!.stopVideoRecording();
      setState(() {
        _isRecording = false;
        _recordProgress = 0.0;
      });

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => CaptureOverlay(
          imagePath: file.path,
          isVideo: true,
          onPost: (caption) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng video thành công (demo)')),
            );
          },
        ),
      );
    } catch (e) {
      debugPrint("Error stopping video: $e");
    }
  }

  Future<void> _init() async {
    await [
      Permission.camera,
      Permission.microphone,
    ].request();

    _cams = await CameraService.available();
    if (_cams.isNotEmpty) {
      _camCtrl = CameraController(_cams.first, ResolutionPreset.high, enableAudio: true);
      await _camCtrl!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _recordTimer = null;
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
                        const GradientCircleIcon(icon: Icons.account_circle_outlined, size: 30),

                        // Friends group
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.black.withOpacity(0.8),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                              ),
                              builder: (_) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        height: 5,
                                        width: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.white24,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Your friends',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...List.generate(
                                        5,
                                        (i) => ListTile(
                                          leading: const CircleAvatar(
                                            backgroundColor: Color.fromARGB(255, 235, 232, 232),
                                            child: Icon(Icons.person, color: Colors.white),
                                          ),
                                          title: Text(
                                            'Bạn ${i + 1}',
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(79, 76, 76, 0.298),
                              borderRadius: BorderRadius.circular(40),
                            ),
                            child: Row(
                              children: [
                                ShaderMask(
                                  shaderCallback: (Rect bounds) =>
                                      instagramGradient.createShader(bounds),
                                  child: const Icon(
                                    Icons.group_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "5",
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    decoration: TextDecoration.none,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Friends",
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
                        ),

                        const GradientCircleIcon(icon: Icons.maps_ugc_outlined, size: 30),
                      ],
                    ),
                  ),

                  // Camera preview
                  Positioned(
                    top: 130,
                    left: 7,
                    right: 7,
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

                  // Progress bar
                  if (_isRecording)
                    Positioned(
                      bottom: 300,
                      left: 20,
                      right: 20,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _recordProgress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
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
                          onTapDown: (_) async {
                            setState(() {
                              _isPressed = true;
                            });
                            await Future.delayed(const Duration(milliseconds: 250));
                            if (_isPressed && !_isRecording) {
                              await _startRecording();
                            }
                          },
                          onTapUp: (_) async {
                            setState(() => _isPressed = false);

                            if (_isRecording) {
                              await _stopRecording(); //
                            } else {
                              _onCapturePressed();
                            }
                          },
                          onTapCancel: () async {
                            setState(() => _isPressed = false);
                            if (_isRecording) {
                              await _stopRecording();
                            }
                          },
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
                                  decoration: BoxDecoration(
                                    color: _isRecording
                                        ? const Color.fromARGB(255, 196, 195, 195)
                                        : Colors.black,
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
                            decoration: TextDecoration.none,
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
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locket_ai/views/camera/capture_preview_page.dart';
import 'package:locket_ai/widgets/base_header.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:locket_ai/widgets/gradient_icon.dart';
import '../../core/services/camera_service.dart';
import 'camera_preview.dart';

class CameraView extends StatefulWidget {
  final PageController verticalController;
  const CameraView({super.key, required this.verticalController});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final PageController _vCtrl;
  CameraController? _camCtrl;
  bool _cameraReady = false;
  List<CameraDescription> _cams = [];
  bool _isPressed = false;
  bool _isRecording = false;
  Timer? _recordTimer;
  final int _maxDuration = 15;

  @override
  void initState() {
    super.initState();
    _vCtrl = PageController(initialPage: 0);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (_cameraReady) return; // tránh khởi tạo lại nhiều lần

    await [Permission.camera, Permission.microphone, Permission.photos].request();

    _cams = await CameraService.available();
    if (_cams.isNotEmpty) {
      _camCtrl = CameraController(
        _cams.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _camCtrl!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _vCtrl.dispose();
    _camCtrl?.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
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
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
              title: const Text("Chọn ảnh", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, "image"),
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: Colors.white),
              title: const Text("Chọn video", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, "video"),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == "image") {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        _showCaptureOverlay(picked.path, false);
      }
    } else if (choice == "video") {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked != null && mounted) {
        _showCaptureOverlay(picked.path, true);
      }
    }
  }

  Future<void> _onCapturePressed() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    final file = await _camCtrl!.takePicture();
    if (!mounted) return;
    _showCaptureOverlay(file.path, false);
  }

  Future<void> _startRecording() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    try {
      await _camCtrl!.startVideoRecording();
      setState(() => _isRecording = true);
      const tick = Duration(milliseconds: 100);
      _recordTimer = Timer.periodic(tick, (timer) {
        if (timer.tick * tick.inSeconds >= _maxDuration) _stopRecording();
      });
    } catch (e) {
      debugPrint("Error starting video: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (_camCtrl == null || !_isRecording) return;
    try {
      _recordTimer?.cancel();
      final file = await _camCtrl!.stopVideoRecording();
      setState(() => _isRecording = false);
      if (!mounted) return;
      _showCaptureOverlay(file.path, true);
    } catch (e) {
      debugPrint("Error stopping video: $e");
    }
  }

  void _showCaptureOverlay(String path, bool isVideo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapturePreviewPage(
          imagePath: path,
          isVideo: isVideo,
          onPost: (caption) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isVideo
                    ? 'Đăng video thành công (demo)'
                    : 'Đăng ảnh thành công (demo)'),
              ),
            );
          },
        ),
      ),
    );

    if (_camCtrl != null && !_camCtrl!.value.isStreamingImages) {
      try {
        await _camCtrl!.initialize();
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _flipCamera() async {
    if (_cams.length < 2) return;
    final current = _cams.indexOf(_camCtrl!.description);
    final next = (current + 1) % _cams.length;
    _camCtrl = CameraController(
      _cams[next],
      ResolutionPreset.high,
      enableAudio: true,
    );
    await _camCtrl!.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PageView(
      controller: _vCtrl,
      scrollDirection: Axis.vertical,
      children: [
        _cameraReady
            ? _buildCameraStack(context)
            : const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent)),
      ],
    );
  }

  Widget _buildCameraStack(BuildContext context) {
    return Stack(
      children: [
        _buildHeader(),
        _buildCameraPreview(),
        if (_isRecording) _buildProgressBar(),
        _buildCaptureControls(),
        _buildBottomText(),
      ],
    );
  }

  Widget _buildHeader() {
    return BaseHeader(
      horizontalController: widget.verticalController,
      count: 5,
      label: 'Friends',
      onTap: _showFriendsSheet
    );
  }

  void _showFriendsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.8),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 16),
          Text('Your friends',
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...List.generate(
            5,
            (i) => ListTile(
              leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAEAEA),
                  child: Icon(Icons.person, color: Colors.white)),
              title: Text('Friend ${i + 1}',
                  style: const TextStyle(color: Colors.white)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size.width;
    return Positioned(
      top: 130,
      left: 7,
      right: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size,
              height: MediaQuery.of(context).size.height * 0.8,
              child: CameraPreviewWidget(controller: _camCtrl!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: 300,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(seconds: _maxDuration),
          onEnd: _stopRecording,
          builder: (_, value, __) => LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor:
                const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Positioned(
      bottom: 180,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
              onTap: _pickFromGallery,
              child: const GradientIcon(icon: Icons.photo_library_outlined, size: 30)),
          GestureDetector(
            onTapDown: (_) async {
              setState(() => _isPressed = true);
              await Future.delayed(const Duration(milliseconds: 250));
              if (_isPressed && !_isRecording) await _startRecording();
            },
            onTapUp: (_) async {
              setState(() => _isPressed = false);
              _isRecording ? await _stopRecording() : _onCapturePressed();
            },
            onTapCancel: () async {
              setState(() => _isPressed = false);
              if (_isRecording) await _stopRecording();
            },
            child: Container(
              height: 90,
              width: 90,
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, gradient: instagramGradient),
              child: Center(
                child: AnimatedScale(
                  scale: _isPressed ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: Container(
                    height: 78,
                    width: 78,
                    decoration: BoxDecoration(
                      color: _isRecording
                          ? const Color(0xFFC4C3C3)
                          : Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
              onTap: _flipCamera,
              child: const GradientIcon(icon: Icons.flip_camera_ios, size: 30)),
        ],
      ),
    );
  }

  Widget _buildBottomText() {
    return Positioned(
      bottom: 70,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text("History",
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none)),
          const GradientIcon(icon: Icons.expand_more),
        ],
      ),
    );
  }
}

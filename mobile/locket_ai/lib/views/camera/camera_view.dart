import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
      builder: (_) => CaptureOverlay(imagePath: file.path, onPost: (caption) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng thành công (demo)')));
      }),
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
                  CameraPreviewWidget(controller: _camCtrl!),
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _onCapturePressed,
                        child: Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 5),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()),
        const FeedView(),
      ],
    );
  }
}

import 'package:camera/camera.dart';

class CameraService {
  static Future<List<CameraDescription>> available() => availableCameras();
}

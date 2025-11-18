import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/camera_viewmodel.dart';

void main() {
  test('submitPost guards against concurrent submissions', () async {
    final vm = CameraViewModel();
    final f1 = vm.submitPost();
    final f2 = vm.submitPost();
    await Future.wait([f1, f2]);
    expect(vm.lastCapturedPath, isNotNull);
  });
}
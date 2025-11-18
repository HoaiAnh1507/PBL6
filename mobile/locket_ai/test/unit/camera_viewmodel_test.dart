import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/camera_viewmodel.dart';

void main() {
  test('CameraViewModel submitPost and reset', () async {
    final vm = CameraViewModel();
    vm.setCaption('hello');
    expect(vm.caption, 'hello');
    expect(vm.isPosting, isFalse);
    await vm.submitPost();
    expect(vm.isPosting, isFalse);
    expect(vm.lastCapturedPath, isNotNull);
    expect(vm.caption, isEmpty);
    vm.reset();
    expect(vm.lastCapturedPath, isNull);
    expect(vm.caption, isEmpty);
  });
}
import 'package:flutter/material.dart';

class CameraViewModel extends ChangeNotifier {
  String? lastCapturedPath;
  String caption = '';
  bool isPosting = false;

  void setCaption(String c) {
    caption = c;
    notifyListeners();
  }

  Future<void> submitPost() async {
    if (isPosting) return;
    isPosting = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    lastCapturedPath = 'local:${DateTime.now().millisecondsSinceEpoch}';
    isPosting = false;
    caption = '';
    notifyListeners();
  }

  void reset() {
    lastCapturedPath = null;
    caption = '';
    notifyListeners();
  }
}

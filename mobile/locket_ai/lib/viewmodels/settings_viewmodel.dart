import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  String username = 'Người dùng';
  void setUsername(String v) {
    username = v;
    notifyListeners();
  }
}

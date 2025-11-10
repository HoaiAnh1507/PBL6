import 'package:flutter/material.dart';

class SettingsViewModel extends ChangeNotifier {
  String username = 'Người dùng';
  bool notificationsEnabled = true;
  bool privateAccount = false;
  void setUsername(String v) {
    username = v;
    notifyListeners();
  }
  void setNotificationsEnabled(bool v) {
    notificationsEnabled = v;
    notifyListeners();
  }
  void setPrivateAccount(bool v) {
    privateAccount = v;
    notifyListeners();
  }
}

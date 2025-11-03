import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'user_viewmodel.dart';

class AuthViewModel extends ChangeNotifier {
  final UserViewModel userViewModel;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthViewModel({required this.userViewModel});

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ Giả lập đăng nhập
  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1)); // mô phỏng chờ request

    try {
      final user = userViewModel.users.firstWhere(
        (u) => u.username == username && u.passwordHash == password,
      );

      if (user.accountStatus == AccountStatus.BANNED) {
        _errorMessage = "Tài khoản đã bị khóa.";
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _currentUser = user;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = "Sai tên đăng nhập hoặc mật khẩu.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // ✅ Đăng xuất
  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}
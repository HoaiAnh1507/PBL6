import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/user_model.dart';
import 'user_viewmodel.dart';
import '../core/config/api_config.dart';

class AuthViewModel extends ChangeNotifier {
  final UserViewModel userViewModel;

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _jwtToken;

  // Base URL và endpoints lấy từ ApiConfig (không định nghĩa lại)

  AuthViewModel({required this.userViewModel});

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get jwtToken => _jwtToken;

  void setJwtToken(String? token) {
    _jwtToken = token;
    notifyListeners();
  }

  // ✅ Đăng nhập bằng API backend
  Future<bool> login(String identifier, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = ApiConfig.endpoint(ApiConfig.loginPath);
      final resp = await http
          .post(
            uri,
            headers: ApiConfig.jsonHeaders(),
            body: jsonEncode({
              'email_or_phonenumber': identifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>?;

        if (token == null || userJson == null) {
          _errorMessage = 'Phản hồi đăng nhập không hợp lệ từ server.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Lưu JWT và ánh xạ user
        setJwtToken(token);
        _currentUser = _mapBackendUser(userJson);

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        String message = 'Đăng nhập thất bại: ${resp.statusCode}';
        try {
          final err = jsonDecode(resp.body);
          if (err is Map && err['message'] is String) {
            message = err['message'];
          } else if (err is Map && err['error'] is String) {
            message = err['error'];
          }
        } catch (_) {}

        _errorMessage = message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: $e';
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

  // ------ Helpers ------
  User _mapBackendUser(Map<String, dynamic> j) {
    // Backend: UserResponse.java
    // Fields: userId, username, fullName, phoneNumber, bio, profilePictureUrl, accountStatus, subscriptionPlan, createdAt
    final createdStr = j['createdAt']?.toString();
    DateTime createdAt;
    try {
      createdAt = createdStr != null ? DateTime.parse(createdStr) : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

    // Map enums an toàn với giá trị mặc định
    SubscriptionStatus subStatus;
    final plan = (j['subscriptionPlan'] ?? '').toString().toUpperCase();
    switch (plan) {
      case 'GOLD':
        subStatus = SubscriptionStatus.GOLD;
        break;
      default:
        subStatus = SubscriptionStatus.FREE;
    }

    AccountStatus accStatus;
    final acc = (j['accountStatus'] ?? '').toString().toUpperCase();
    switch (acc) {
      case 'SUSPENDED':
        accStatus = AccountStatus.SUSPENDED;
        break;
      case 'BANNED':
        accStatus = AccountStatus.BANNED;
        break;
      default:
        accStatus = AccountStatus.ACTIVE;
    }

    return User(
      userId: j['userId']?.toString() ?? 'unknown',
      phoneNumber: j['phoneNumber']!.toString(),
      username: j['username']?.toString() ?? '',
      email: j['email']?.toString() ?? '', // Backend hiện không trả email → để trống
      fullName: j['fullName']?.toString() ?? '',
      profilePictureUrl: j['profilePictureUrl']?.toString(),
      passwordHash: '',
      subscriptionStatus: subStatus,
      subscriptionExpiresAt: null,
      accountStatus: accStatus,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }
}
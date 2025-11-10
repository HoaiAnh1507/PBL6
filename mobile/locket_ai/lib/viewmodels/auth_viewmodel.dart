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
      final uri = ApiConfig.endpoint(ApiConfig.authLoginPath);
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
    _errorMessage = 'Invalid login response from server.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // Lưu JWT và ánh xạ user
        setJwtToken(token);
        _currentUser = _mapBackendUser(userJson);
        // Enrich profile with full fields (e.g. email) from /api/users/profile
        try {
          final enriched = await userViewModel.fetchOwnProfile(token);
          if (enriched != null) {
            _currentUser = enriched;
          }
        } catch (_) {}

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
    String message = 'Login failed: ${resp.statusCode}';
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

  // ✅ Đăng xuất: gọi backend để blacklist token, rồi xóa trạng thái local
  Future<void> logout() async {
    try {
      final uri = ApiConfig.endpoint(ApiConfig.authLogoutPath);
      await http.post(
        uri,
        headers: ApiConfig.jsonHeaders(jwt: _jwtToken),
      ).timeout(const Duration(seconds: 8));
    } catch (_) {
      // Bỏ qua lỗi, vẫn xóa local
    }
    _currentUser = null;
    _jwtToken = null;
    notifyListeners();
  }

  // ✅ Đăng ký tài khoản mới
  Future<bool> register({
    required String username,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = ApiConfig.endpoint(ApiConfig.authRegisterPath);
      final resp = await http
          .post(
            uri,
            headers: ApiConfig.jsonHeaders(),
            body: jsonEncode({
              'username': username,
              'password': password,
              'fullName': fullName,
              'phoneNumber': phoneNumber,
              'email': email,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final token = data['token'] as String?;
        final userJson = data['user'] as Map<String, dynamic>?;

        if (token == null || userJson == null) {
    _errorMessage = 'Invalid registration response from server.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        setJwtToken(token);
        _currentUser = _mapBackendUser(userJson);
        userViewModel.setCurrentUser(_currentUser!);
        // Enrich profile with full fields from /api/users/profile
        try {
          final enriched = await userViewModel.fetchOwnProfile(token);
          if (enriched != null) {
            _currentUser = enriched;
          }
        } catch (_) {}

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
    String message = 'Registration failed: ${resp.statusCode}';
        try {
          final err = jsonDecode(resp.body);
          if (err is Map && err['error'] is String) message = err['error'];
          if (err is Map && err['message'] is String) message = err['message'];
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

  // ✅ Lấy thông tin user hiện tại từ backend (/api/auth/me)
  Future<bool> fetchMe() async {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
    _errorMessage = 'JWT token missing';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    notifyListeners();
    try {
      final uri = ApiConfig.endpoint(ApiConfig.authMePath);
      final resp = await http
          .get(
            uri,
            headers: ApiConfig.jsonHeaders(jwt: _jwtToken),
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        _currentUser = _mapBackendUser(data);
        userViewModel.setCurrentUser(_currentUser!);
        // Enrich profile from /api/users/profile to include fields missing in /api/auth/me
        try {
          final enriched = await userViewModel.fetchOwnProfile(_jwtToken!);
          if (enriched != null) {
            _currentUser = enriched;
          }
        } catch (_) {}
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
    _errorMessage = 'Failed to fetch user info (${resp.statusCode})';
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

  // ✅ Quên mật khẩu
  Future<bool> forgotPassword(String emailOrPhone) async {
    _errorMessage = null;
    try {
      final uri = ApiConfig.endpoint(ApiConfig.authForgotPasswordPath);
      final resp = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders(),
        body: jsonEncode({'email_or_phonenumber': emailOrPhone}),
      );
      if (resp.statusCode == 200) {
        return true;
      }
      try {
        final err = jsonDecode(resp.body);
        if (err is Map && err['error'] is String) _errorMessage = err['error'];
      } catch (_) {}
      return false;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: $e';
      return false;
    }
  }

  // ✅ Đặt lại mật khẩu (yêu cầu JWT)
  Future<bool> resetPassword(String username, String newPassword) async {
    if (_jwtToken == null || _jwtToken!.isEmpty) {
    _errorMessage = 'Not logged in';
      return false;
    }
    try {
      final uri = ApiConfig.endpoint(ApiConfig.authResetPasswordPath);
      final resp = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders(jwt: _jwtToken),
        body: jsonEncode({'username': username, 'password': newPassword}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: $e';
      return false;
    }
  }

  // ✅ Xác thực OTP
  Future<bool> verifyOtp({required String email, required String code}) async {
    try {
      final uri = ApiConfig.endpoint(ApiConfig.authVerifyOtpPath);
      final resp = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders(),
        body: jsonEncode({'email': email, 'code': code}),
      );
      return resp.statusCode == 200;
    } catch (e) {
      _errorMessage = 'Lỗi kết nối: $e';
      return false;
    }
  }

  // ✅ Kiểm tra tính khả dụng của email
  Future<bool> checkEmailAvailability(String email) async {
    try {
      final uri = ApiConfig.endpoint('${ApiConfig.authCheckEmailPath}?email=$email');
      final resp = await http.get(uri, headers: ApiConfig.jsonHeaders());
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['available'] == true);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ✅ Kiểm tra tính khả dụng của số điện thoại
  Future<bool> checkPhoneAvailability(String phoneNumber) async {
    try {
      final uri = ApiConfig.endpoint('${ApiConfig.authCheckPhonePath}?phoneNumber=$phoneNumber');
      final resp = await http.get(uri, headers: ApiConfig.jsonHeaders());
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return (data['available'] == true);
      }
      return false;
    } catch (_) {
      return false;
    }
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
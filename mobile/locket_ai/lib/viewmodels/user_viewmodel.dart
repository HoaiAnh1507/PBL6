import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../core/config/api_config.dart';

class UserViewModel extends ChangeNotifier {
  final List<User> _users = [];
  User? _currentUser;

  List<User> get users => List.unmodifiable(_users);
  User? get currentUser => _currentUser;

  UserViewModel() {
    _loadMockData();
  }

  void _loadMockData() {
    final now = DateTime.now();

    _users.addAll([
      User(
        userId: 'u0',
        phoneNumber: '0900000000',
        username: 'me',
        email: 'me@example.com',
        fullName: 'Tôi',
        profilePictureUrl: 'https://i.pravatar.cc/150?img=5',
        passwordHash: 'me',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: now,
        updatedAt: now,
      ),
      User(
        userId: 'u1',
        phoneNumber: '0900000001',
        username: 'tuan',
        email: 'tuan@example.com',
        fullName: 'Nguyen Van Tuan',
        profilePictureUrl: 'https://i.pravatar.cc/150?img=1',
        passwordHash: 'hash1',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.ACTIVE,
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now,
      ),
      User(
        userId: 'u2',
        phoneNumber: '0900000002',
        username: 'hieu',
        email: 'hieu@example.com',
        fullName: 'Tran Van Hieu',
        profilePictureUrl: 'https://i.pravatar.cc/150?img=2',
        passwordHash: 'hash2',
        subscriptionStatus: SubscriptionStatus.GOLD,
        subscriptionExpiresAt: now.add(const Duration(days: 15)),
        accountStatus: AccountStatus.ACTIVE,
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now,
      ),
      User(
        userId: 'u3',
        phoneNumber: '0900000003',
        username: 'rin',
        email: 'rin@example.com',
        fullName: 'Nguyen Thi Rin',
        profilePictureUrl: 'https://i.pravatar.cc/150?img=3',
        passwordHash: 'hash3',
        subscriptionStatus: SubscriptionStatus.FREE,
        subscriptionExpiresAt: null,
        accountStatus: AccountStatus.SUSPENDED,
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now,
      ),
    ]);

    notifyListeners();
  }

  // ✅ Login
  void login(String userId) {
    final found = _users.firstWhere(
      (u) => u.userId == userId,
      orElse: () => throw Exception("User not found $userId"),
    );
    _currentUser = found;
    notifyListeners();
  }

  // ✅ Set current user từ Auth (thêm vào danh sách nếu chưa có)
  void setCurrentUser(User user) {
    final idx = _users.indexWhere((u) => u.userId == user.userId);
    if (idx == -1) {
      _users.insert(0, user);
    } else {
      _users[idx] = user;
    }
    _currentUser = user;
    notifyListeners();
  }

  // ✅ Logout
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // ✅ Lấy user theo ID
  User? getUserById(String userId) {
    final idx = _users.indexWhere((u) => u.userId == userId);
    if (idx == -1) return null;
    return _users[idx];
  }

  // ===== Backend integration =====
  // ✅ Lấy hồ sơ của chính mình từ backend
  Future<User?> fetchOwnProfile(String jwt) async {
    try {
      final uri = ApiConfig.endpoint(ApiConfig.usersProfilePath);
      final resp = await http.get(uri, headers: ApiConfig.jsonHeaders(jwt: jwt));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final user = _mapBackendUser(data);
        setCurrentUser(user);
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ✅ Cập nhật hồ sơ của mình
  Future<User?> updateProfile({
    required String jwt,
    String? fullName,
    String? phoneNumber,
    String? email,
    String? profilePictureUrl,
  }) async {
    try {
      final uri = ApiConfig.endpoint(ApiConfig.usersProfilePath);
      final body = <String, dynamic>{};
      if (fullName != null) body['fullName'] = fullName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (email != null) body['email'] = email;
      if (profilePictureUrl != null) body['profilePictureUrl'] = profilePictureUrl;

      final resp = await http.patch(
        uri,
        headers: ApiConfig.jsonHeaders(jwt: jwt),
        body: jsonEncode(body),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final updated = _mapBackendUser(data);
        setCurrentUser(updated);
        return updated;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ✅ Lấy người dùng theo ID từ backend (PublicUserResponse)
  Future<User?> fetchUserById({required String id, required String jwt}) async {
    try {
      final uri = ApiConfig.endpoint(ApiConfig.usersByIdPath(id));
      final resp = await http.get(uri, headers: ApiConfig.jsonHeaders(jwt: jwt));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        // PublicUserResponse không có tất cả trường; map tối thiểu
        final user = User(
          userId: data['userId']?.toString() ?? id,
          username: data['username']?.toString() ?? '',
          fullName: data['fullName']?.toString() ?? '',
          phoneNumber: data['phoneNumber']?.toString() ?? '',
          email: data['email']?.toString() ?? '',
          profilePictureUrl: data['profilePictureUrl']?.toString(),
          passwordHash: '',
          subscriptionStatus: SubscriptionStatus.FREE,
          subscriptionExpiresAt: null,
          accountStatus: AccountStatus.ACTIVE,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        // Không set currentUser; chỉ thêm vào danh sách nếu chưa có
        final idx = _users.indexWhere((u) => u.userId == user.userId);
        if (idx == -1) {
          _users.add(user);
          notifyListeners();
        } else {
          _users[idx] = user;
          notifyListeners();
        }
        return user;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ✅ Tìm kiếm người dùng
  Future<List<User>> searchUsers({required String jwt, String? query}) async {
    try {
      final path = ApiConfig.usersSearchPath(q: query);
      final uri = ApiConfig.endpoint(path);
      final resp = await http.get(uri, headers: ApiConfig.jsonHeaders(jwt: jwt));
      if (resp.statusCode == 200) {
        final arr = jsonDecode(resp.body) as List<dynamic>;
        final results = arr.map((e) {
          final j = e as Map<String, dynamic>;
          return User(
            userId: j['userId']?.toString() ?? '',
            username: j['username']?.toString() ?? '',
            fullName: j['fullName']?.toString() ?? '',
            phoneNumber: j['phoneNumber']?.toString() ?? '',
            email: j['email']?.toString() ?? '',
            profilePictureUrl: j['profilePictureUrl']?.toString(),
            passwordHash: '',
            subscriptionStatus: SubscriptionStatus.FREE,
            subscriptionExpiresAt: null,
            accountStatus: AccountStatus.ACTIVE,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }).toList();
        return results;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ✅ Lấy URL tải lên avatar
  Future<Map<String, dynamic>?> getAvatarUploadUrl({
    required String jwt,
    required String fileName,
    required String contentType,
  }) async {
    try {
      final uri = ApiConfig.endpoint(ApiConfig.usersAvatarUploadUrlPath);
      final resp = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders(jwt: jwt),
        body: jsonEncode({
          'fileName': fileName,
          'contentType': contentType,
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        return data; // { uploadUrl, fileKey, method, expiresIn, headers }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ✅ Upload avatar from a local file using signed upload URL
  Future<String?> uploadAvatarFromFile({
    required String jwt,
    required File file,
  }) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final contentType = _guessMimeType(file.path);
      final data = await getAvatarUploadUrl(jwt: jwt, fileName: fileName, contentType: contentType);
      if (data == null) return null;
      final uploadUrl = data['uploadUrl']?.toString();
      final fileKey = data['fileKey']?.toString();
      final headersDynamic = data['headers'];
      final headers = <String, String>{};
      if (headersDynamic is Map) {
        headers.addAll(headersDynamic.map((k, v) => MapEntry(k.toString(), v.toString())));
      }
      // Fallback ensure Content-Type is present
      headers.putIfAbsent('Content-Type', () => contentType);
      // Azure Blob SAS often requires x-ms-blob-type
      if (uploadUrl != null && uploadUrl.contains('blob.core.windows.net') && !headers.containsKey('x-ms-blob-type')) {
        headers['x-ms-blob-type'] = 'BlockBlob';
      }
      final bytes = await file.readAsBytes();
      final method = (data['method']?.toString().toUpperCase() ?? 'PUT');
      http.Response putResp;
      if (method == 'POST') {
        // Support presigned POST (e.g., S3) with multipart form fields
        final fieldsDynamic = data['fields'];
        if (fieldsDynamic is Map) {
          final req = http.MultipartRequest('POST', Uri.parse(uploadUrl!));
          fieldsDynamic.forEach((k, v) => req.fields[k.toString()] = v.toString());
          req.files.add(http.MultipartFile.fromBytes('file', bytes, filename: fileName, contentType: MediaType.parse(contentType)));
          headers.forEach((k, v) => req.headers[k] = v);
          final streamed = await req.send();
          final respBytes = await streamed.stream.toBytes();
          putResp = http.Response.bytes(respBytes, streamed.statusCode, headers: streamed.headers, request: streamed.request);
        } else {
          // Generic POST with raw body
          putResp = await http.post(Uri.parse(uploadUrl!), headers: headers, body: bytes);
        }
      } else {
        putResp = await http.put(Uri.parse(uploadUrl!), headers: headers, body: bytes);
      }
      // Accept common success codes: 200 (OK), 201 (Created), 204 (No Content)
      if (putResp.statusCode == 200 || putResp.statusCode == 201 || putResp.statusCode == 204) {
        return fileKey; // return storage key to be saved as profilePictureUrl
      }
      debugPrint('Avatar upload failed: ${putResp.statusCode} ${putResp.reasonPhrase}');
      return null;
    } catch (e) {
      debugPrint('Avatar upload error: $e');
      return null;
    }
  }

  String _guessMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
  }

  // ✅ Xóa tài khoản của chính mình (yêu cầu OTP code)
  Future<bool> deleteOwnAccount({required String jwt, required String code}) async {
    try {
      final uri = ApiConfig.endpoint(ApiConfig.usersDeleteMePath);
      final resp = await http.delete(
        uri,
        headers: ApiConfig.jsonHeaders(jwt: jwt),
        body: jsonEncode({'code': code}),
      );
      if (resp.statusCode == 200) {
        _currentUser = null;
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ------ Map helper từ UserResponse (backend) sang User (app) ------
  User _mapBackendUser(Map<String, dynamic> j) {
    final createdStr = j['createdAt']?.toString();
    DateTime createdAt;
    try {
      createdAt = createdStr != null ? DateTime.parse(createdStr) : DateTime.now();
    } catch (_) {
      createdAt = DateTime.now();
    }

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
      phoneNumber: j['phoneNumber']?.toString() ?? '',
      username: j['username']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
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

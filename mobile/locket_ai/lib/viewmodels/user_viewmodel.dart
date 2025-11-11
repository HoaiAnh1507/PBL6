import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user_model.dart';
import '../core/config/api_config.dart';

class UserViewModel extends ChangeNotifier {
  final List<User> _users = [];
  User? _currentUser;
  String? lastUploadError;
  final Map<String, String?> _displayUrlCache = {};

  List<User> get users => List.unmodifiable(_users);
  User? get currentUser => _currentUser;

  UserViewModel() {
    _loadMockData();
  }

  // ✅ Xóa cache URL hiển thị (SAS) để buộc tải lại avatar sau khi cập nhật
  void clearDisplayUrlCache() {
    _displayUrlCache.clear();
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
      final bodyText = resp.body.isNotEmpty ? resp.body : '(no body)';
      lastUploadError = 'getAvatarUploadUrl failed: status=' + resp.statusCode.toString() + ' body=' + bodyText;
      return null;
    } catch (e) {
      lastUploadError = 'getAvatarUploadUrl error: ' + e.toString();
      return null;
    }
  }

  // ✅ Lấy SAS upload cho container 'avatar' từ backend
  Future<Map<String, dynamic>?> getAvatarSasUpload({
    required String jwt,
    required String blobName,
    required String contentType,
  }) async {
    try {
      final uri = ApiConfig.endpoint(ApiConfig.storageSasPath);
      final resp = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders(jwt: jwt),
        body: jsonEncode({
          // Align with media upload request body which uses `containerName`
          'containerName': 'avatar',
          'access': 'upload',
          'expiresInSeconds': 300,
          'mediaType': 'PHOTO',
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        // Expected: { uploadUrl, blobUrl, expiresAt }
        return data;
      }
      final bodyText = resp.body.isNotEmpty ? resp.body : '(no body)';
      lastUploadError = 'getAvatarSasUpload failed: status=' + resp.statusCode.toString() + ' body=' + bodyText;
      return null;
    } catch (e) {
      lastUploadError = 'getAvatarSasUpload error: ' + e.toString();
      return null;
    }
  }

  // ✅ Upload avatar from a local file using signed upload URL
  Future<String?> uploadAvatarFromFile({
    required String jwt,
    required File file,
  }) async {
    try {
      final contentType = _guessMimeType(file.path);

      // Use SAS flow like PostService: request SAS, then PUT directly to Azure
      final uri = ApiConfig.endpoint(ApiConfig.storageSasPath);
      final sasResp = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders(jwt: jwt),
        body: jsonEncode({
          'containerName': 'avatar',
          'access': 'upload',
          'expiresInSeconds': 300,
          'mediaType': 'PHOTO',
        }),
      );
      if (sasResp.statusCode != 200) {
        final bodyText = sasResp.body.isNotEmpty ? sasResp.body : '(no body)';
        lastUploadError = 'getAvatarSasUpload failed: status=${sasResp.statusCode} body=$bodyText';
        debugPrint('Avatar SAS request failed: $lastUploadError');
        return null;
      }
      final data = jsonDecode(sasResp.body) as Map<String, dynamic>;
      final signedUrl = (data['uploadUrl']?.toString()) ?? (data['signedUrl']?.toString());
      if (signedUrl == null) {
        lastUploadError = 'getAvatarSasUpload missing signedUrl/uploadUrl';
        return null;
      }

      final bytes = await file.readAsBytes();
      final putHeaders = <String, String>{
        'x-ms-blob-type': 'BlockBlob',
        'x-ms-version': '2020-10-02',
        'x-ms-blob-content-type': contentType,
        'Content-Type': contentType,
      };
      final putResp = await http.put(Uri.parse(signedUrl), headers: putHeaders, body: bytes);
      if (putResp.statusCode == 200 || putResp.statusCode == 201 || putResp.statusCode == 204) {
        lastUploadError = null;
        final blobUrl = signedUrl.split('?').first;
        return blobUrl;
      }
      final bodyText = putResp.body.isNotEmpty ? putResp.body : '(no body)';
      final shortHeaders = putHeaders.entries.map((e) => '${e.key}=${e.value}').join('; ');
      lastUploadError = 'Azure PUT failed: status=${putResp.statusCode} reason=${putResp.reasonPhrase} url=$signedUrl headers=$shortHeaders body=$bodyText';
      debugPrint('Avatar Azure PUT failed: $lastUploadError');
      return null;
    } catch (e) {
      lastUploadError = 'uploadAvatarFromFile exception: ' + e.toString();
      debugPrint('Avatar upload error: $e');
      return null;
    }
  }

  // ✅ Resolve displayable URL for a blob: if private Azure blob URL (no query), request READ SAS
  Future<String?> resolveDisplayUrl({
    required String jwt,
    required String? url,
  }) async {
    try {
      if (url == null || url.isEmpty) return null;
      final cacheKey = jwt + '|' + url;
      if (_displayUrlCache.containsKey(cacheKey)) {
        return _displayUrlCache[cacheKey];
      }
      // If already has query or is not azure blob, use as-is
      if (!url.contains('blob.core.windows.net') || url.contains('?')) {
        _displayUrlCache[cacheKey] = url;
        return url;
      }
      // Parse container and blobName from URL
      final u = Uri.parse(url);
      if (u.pathSegments.isEmpty) return url;
      final container = u.pathSegments.first;
      final blobName = u.pathSegments.sublist(1).join('/');
      if (blobName.isEmpty) return url;

      final uri = ApiConfig.endpoint(ApiConfig.storageSasPath);
      final resp = await http.post(
        uri,
        headers: ApiConfig.jsonHeaders(jwt: jwt),
        body: jsonEncode({
          'containerName': container,
          'access': 'read',
          'blobName': blobName,
          'expiresInSeconds': 300,
        }),
      );
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final resolved = (data['signedUrl']?.toString()) ?? (data['uploadUrl']?.toString()) ?? url;
        _displayUrlCache[cacheKey] = resolved;
        return resolved;
      }
      // Fall back to original URL if cannot get SAS
      final bodyText = resp.body.isNotEmpty ? resp.body : '(no body)';
      lastUploadError = 'resolveDisplayUrl failed: status=${resp.statusCode} body=$bodyText';
      _displayUrlCache[cacheKey] = url;
      return url;
    } catch (e) {
      lastUploadError = 'resolveDisplayUrl error: ' + e.toString();
      return url;
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

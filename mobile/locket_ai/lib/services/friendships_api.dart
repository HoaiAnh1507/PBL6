import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class FriendshipsApi {
  final String jwt;
  FriendshipsApi(this.jwt);

  Map<String, String> get _headers => ApiConfig.jsonHeaders(jwt: jwt);

  /// GET /api/friendships/requests → { incoming: FriendshipResponse[], sent: FriendshipResponse[] }
  Future<Map<String, dynamic>> listRequests() async {
    final uri = ApiConfig.endpoint(ApiConfig.friendshipsRequestsPath);
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      return (data is Map<String, dynamic>) ? data : <String, dynamic>{};
    }
    return <String, dynamic>{};
  }

  /// GET /api/friendships → PublicUserResponse[]
  Future<List<dynamic>> listFriends() async {
    final uri = ApiConfig.endpoint(ApiConfig.friendshipsBasePath);
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode == 200) {
      try {
        return jsonDecode(resp.body) as List<dynamic>;
      } catch (_) {
        return [];
      }
    }
    return [];
  }

  Future<bool> sendRequest(String targetUsername) async {
    final uri = ApiConfig.endpoint(ApiConfig.friendshipsRequestPath(targetUsername));
    final resp = await http.post(uri, headers: _headers);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<bool> accept(String senderUsername) async {
    final uri = ApiConfig.endpoint(ApiConfig.friendshipsAcceptPath(senderUsername));
    final resp = await http.post(uri, headers: _headers);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<bool> reject(String senderUsername) async {
    final uri = ApiConfig.endpoint(ApiConfig.friendshipsRejectPath(senderUsername));
    final resp = await http.post(uri, headers: _headers);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<bool> block(String targetUsername) async {
    final uri = ApiConfig.endpoint(ApiConfig.friendshipsBlockPath(targetUsername));
    final resp = await http.post(uri, headers: _headers);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  Future<bool> unblock(String targetUsername) async {
    final uri = ApiConfig.endpoint(ApiConfig.friendshipsUnblockPath(targetUsername));
    final resp = await http.post(uri, headers: _headers);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }

  /// DELETE /api/friendships/unfriend/{targetUsername}
  Future<bool> unfriend(String targetUsername) async {
    final uri = ApiConfig.endpoint(ApiConfig.friendshipsUnfriendPath(targetUsername));
    final resp = await http.delete(uri, headers: _headers);
    return resp.statusCode >= 200 && resp.statusCode < 300;
  }
}
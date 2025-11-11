import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class PostsApi {
  final String jwt;
  PostsApi({required this.jwt});

  Map<String, String> get _headers => ApiConfig.jsonHeaders(jwt: jwt);

  Future<List<dynamic>> listPosts() async {
    final uri = ApiConfig.endpoint(ApiConfig.postsBasePath);
    final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      try {
        final decoded = jsonDecode(resp.body);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded['items'] is List) return List<dynamic>.from(decoded['items']);
      } catch (_) {}
    }
    return [];
  }
}
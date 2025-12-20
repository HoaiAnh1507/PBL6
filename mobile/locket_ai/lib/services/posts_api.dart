import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'package:flutter/foundation.dart';

class PostsApi {
  final String jwt;
  PostsApi({required this.jwt});

  Map<String, String> get _headers => ApiConfig.jsonHeaders(jwt: jwt);

  /// GET /api/posts/feed → Danh sách bài đăng tôi đăng + người khác chia sẻ cho tôi
  /// Supports pagination: beforePostId (cursor) and limit
  Future<List<dynamic>> listFeed({
    String? beforePostId,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (beforePostId != null && beforePostId.isNotEmpty) {
      queryParams['beforePostId'] = beforePostId;
    }
    final uri = ApiConfig.endpoint(ApiConfig.postsFeedPath)
        .replace(queryParameters: queryParams);
    try {
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) return decoded;
          if (decoded is Map) {
            final possibleKeys = ['items', 'data', 'content', 'results', 'posts'];
            for (final key in possibleKeys) {
              final val = decoded[key];
              if (val is List) {
                return List<dynamic>.from(val);
              }
            }
          }
          debugPrint('[PostsApi] Unexpected feed response: ${resp.body.substring(0, resp.body.length < 500 ? resp.body.length : 500)}');
        } catch (e) {
          debugPrint('[PostsApi] JSON decode error (feed): $e');
        }
      } else {
        debugPrint('[PostsApi] listFeed failed: status=${resp.statusCode} body=${resp.body.isNotEmpty ? resp.body.substring(0, resp.body.length < 500 ? resp.body.length : 500) : '(empty)'}');
      }
    } catch (e) {
      debugPrint('[PostsApi] HTTP error (feed): $e');
    }
    return [];
  }

  /// GET /api/posts/shared-to-me/from/{username} → Bài bạn đó chia sẻ cho tôi
  Future<List<dynamic>> listSharedToMeFrom(String username) async {
    final path = ApiConfig.postsSharedToMeFromPath(username);
    final uri = ApiConfig.endpoint(path);
    try {
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) return decoded;
          if (decoded is Map) {
            final possibleKeys = ['items', 'data', 'content', 'results', 'posts'];
            for (final key in possibleKeys) {
              final val = decoded[key];
              if (val is List) {
                return List<dynamic>.from(val);
              }
            }
          }
          debugPrint('[PostsApi] Unexpected shared-from response: ${resp.body.substring(0, resp.body.length < 500 ? resp.body.length : 500)}');
        } catch (e) {
          debugPrint('[PostsApi] JSON decode error (shared-from): $e');
        }
      } else {
        debugPrint('[PostsApi] listSharedToMeFrom failed: status=${resp.statusCode} body=${resp.body.isNotEmpty ? resp.body.substring(0, resp.body.length < 500 ? resp.body.length : 500) : '(empty)'}');
      }
    } catch (e) {
      debugPrint('[PostsApi] HTTP error (shared-from): $e');
    }
    return [];
  }

  Future<List<String>> addReaction({required String postId, required String emojiType}) async {
    final uri = ApiConfig.endpoint(ApiConfig.postReactionsPath(postId));
    try {
      final resp = await http
          .post(uri,
              headers: _headers,
              body: jsonEncode({
                'emojiType': emojiType,
              }))
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map && decoded['reaction'] is List) {
            return List<String>.from((decoded['reaction'] as List).map((e) => e.toString()));
          }
        } catch (_) {}
      } else {
        debugPrint('[PostsApi] addReaction failed: status=${resp.statusCode} body=${resp.body}');
      }
    } catch (e) {
      debugPrint('[PostsApi] HTTP error (addReaction): $e');
    }
    return <String>[];
  }

  Future<Map<String, dynamic>?> getReactions({required String postId}) async {
    final uri = ApiConfig.endpoint(ApiConfig.postReactionsPath(postId));
    try {
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 12));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map<String, dynamic>) return decoded;
        } catch (e) {
          debugPrint('[PostsApi] JSON decode error (getReactions): $e');
        }
      } else {
        debugPrint('[PostsApi] getReactions failed: status=${resp.statusCode} body=${resp.body}');
      }
    } catch (e) {
      debugPrint('[PostsApi] HTTP error (getReactions): $e');
    }
    return null;
  }
}
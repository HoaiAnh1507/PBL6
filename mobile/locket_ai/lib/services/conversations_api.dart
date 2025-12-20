import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class ConversationsApi {
  final String jwt;
  ConversationsApi(this.jwt);

  Map<String, String> get _headers => ApiConfig.jsonHeaders(jwt: jwt);

  Future<List<dynamic>> listConversations() async {
    final uri = ApiConfig.endpoint(ApiConfig.conversationsBasePath);
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body) as List<dynamic>;
    }
    return [];
  }

  Future<Map<String, dynamic>?> getConversationById(String conversationId) async {
    final uri = ApiConfig.endpoint(ApiConfig.conversationByIdPath(conversationId));
    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode == 200) {
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// GET /api/conversations/{conversationId}/messages with pagination
  /// Returns list of messages sorted from old to new
  Future<List<dynamic>> getConversationMessages(
    String conversationId, {
    String? beforeMessageId,
    int limit = 25,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    if (beforeMessageId != null && beforeMessageId.isNotEmpty) {
      queryParams['beforeMessageId'] = beforeMessageId;
    }
    final path = '/api/conversations/$conversationId/messages';
    final uri = ApiConfig.endpoint(path)
        .replace(queryParameters: queryParams);
    try {
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 20));
      if (resp.statusCode == 200) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) return decoded;
          return [];
        } catch (_) {
          return [];
        }
      }
    } catch (_) {}
    return [];
  }
}
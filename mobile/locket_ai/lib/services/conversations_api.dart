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
}
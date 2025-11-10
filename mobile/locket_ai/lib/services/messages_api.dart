import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';

class MessagesApi {
  final String jwt;
  MessagesApi(this.jwt);

  Map<String, String> get _headers => ApiConfig.jsonHeaders(jwt: jwt);

  // Reply to a post (send message referencing a post)
  Future<bool> replyPost({
    required String conversationId,
    required String postId,
    required String content,
  }) async {
    final uri = ApiConfig.endpoint(ApiConfig.messagesReplyPostPath);
    final body = {
      'conversationId': conversationId,
      'postId': postId,
      'content': content,
    };
    final resp = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    return resp.statusCode == 200;
  }
}
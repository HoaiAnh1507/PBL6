import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/api_config.dart';
import 'package:flutter/foundation.dart';

class ReportsApi {
  final String jwt;
  ReportsApi({required this.jwt});

  Map<String, String> get _headers => ApiConfig.jsonHeaders(jwt: jwt);

  /// POST /api/reports → Tạo report mới cho post
  Future<Map<String, dynamic>?> createReport({
    required String postId,
    required String reason,
  }) async {
    final uri = ApiConfig.endpoint(ApiConfig.reportsBasePath);
    try {
      final body = jsonEncode({
        'reportedPostId': postId,
        'reason': reason,
      });
      
      final resp = await http
          .post(uri, headers: _headers, body: body)
          .timeout(const Duration(seconds: 15));
      
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        } catch (e) {
          debugPrint('[ReportsApi] JSON decode error: $e');
        }
      } else {
        debugPrint('[ReportsApi] createReport failed: status=${resp.statusCode} body=${resp.body}');
      }
    } catch (e) {
      debugPrint('[ReportsApi] HTTP error (createReport): $e');
    }
    return null;
  }

  /// GET /api/reports/my → Lấy danh sách reports của user đã tạo
  Future<List<dynamic>> getMyReports({int page = 0, int size = 10}) async {
    final uri = ApiConfig.endpoint('${ApiConfig.reportsBasePath}/my?page=$page&size=$size');
    try {
      final resp = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 15));
      
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        try {
          final decoded = jsonDecode(resp.body);
          if (decoded is List) return decoded;
          if (decoded is Map) {
            // Nếu response là paginated
            if (decoded['content'] is List) {
              return List<dynamic>.from(decoded['content']);
            }
          }
        } catch (e) {
          debugPrint('[ReportsApi] JSON decode error (getMyReports): $e');
        }
      } else {
        debugPrint('[ReportsApi] getMyReports failed: status=${resp.statusCode} body=${resp.body}');
      }
    } catch (e) {
      debugPrint('[ReportsApi] HTTP error (getMyReports): $e');
    }
    return [];
  }
}

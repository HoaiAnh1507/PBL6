// Centralized API configuration for backend access
// Provides baseUrl, endpoints, and helpers to build URIs and headers

class ApiConfig {
  // Base URL read from --dart-define BACKEND_BASE_URL
  // Default aligns with your current LAN IP setup
  static String _baseUrl = const String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://192.168.0.42:8080',
  );

  static String get baseUrl => _baseUrl;
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  // Common API paths
  static const String loginPath = '/api/auth/login';
  static const String storageSasPath = '/api/storage/sas';
  static const String postsAiInitPath = '/api/posts/ai/init';
  static String captionStatusPath(String postId) => '/api/posts/$postId/caption-status';

  // Azure Blob default container name (centralized)
  static String _storageContainerName = 'post';
  static String get storageContainerName => _storageContainerName;
  static void setStorageContainerName(String name) {
    _storageContainerName = name;
  }

  // Build absolute endpoint URI from a path
  static Uri endpoint(String path) => Uri.parse('$_baseUrl$path');

  // Default JSON headers; attach Bearer token if provided
  static Map<String, String> jsonHeaders({String? jwt}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (jwt != null && jwt.isNotEmpty) {
      headers['Authorization'] = 'Bearer $jwt';
    }
    return headers;
  }
}
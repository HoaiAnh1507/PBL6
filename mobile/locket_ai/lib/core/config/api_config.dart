// Centralized API configuration for backend access
// Provides baseUrl, endpoints, and helpers to build URIs and headers

class ApiConfig {
  // Base URL read from --dart-define BACKEND_BASE_URL
  // Default aligns with your current LAN IP setup
  static String _baseUrl = const String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://192.168.1.4:8080',
  );

  static String get baseUrl => _baseUrl;
  static void setBaseUrl(String url) {
    _baseUrl = url;
  }

  // Common API paths
  // Auth
  static const String authRegisterPath = '/api/auth/register';
  static const String authLoginPath = '/api/auth/login';
  static const String authLogoutPath = '/api/auth/logout';
  static const String authMePath = '/api/auth/me';
  static const String authForgotPasswordPath = '/api/auth/forgot-password';
  static const String authResetPasswordPath = '/api/auth/reset-password';
  static const String authVerifyOtpPath = '/api/auth/verify-otp';
  static const String authCheckEmailPath = '/api/auth/check-email';
  static const String authCheckPhonePath = '/api/auth/check-phone';

  // Storage
  static const String storageSasPath = '/api/storage/sas';

  // Posts
  static const String postsBasePath = '/api/posts';
  static const String postsFeedPath = '/api/posts/feed';
  static String postsSharedToMeFromPath(String username) => '/api/posts/shared-to-me/from/$username';
  static const String postsAiInitPath = '/api/posts/ai/init';
  static const String postsAiCommitPath = '/api/posts/ai/commit';
  static String postDeletePath(String postId) => '/api/posts/$postId';
  static String captionStatusPath(String postId) => '/api/posts/$postId/caption-status';
  static String postReactionsPath(String postId) => '/api/posts/$postId/reactions';

  // Users
  static const String usersBasePath = '/api/users';
  static String usersByIdPath(String id) => '/api/users/$id';
  static const String usersProfilePath = '/api/users/profile'; // GET/PATCH
  static const String usersAvatarUploadUrlPath = '/api/users/avatar/upload-url';
  static const String usersDeleteMePath = '/api/users/me';
  static String usersSearchPath({String? q}) => '/api/users/search${(q!=null && q.isNotEmpty) ? '?q=$q' : ''}';

  // Friendships
  static const String friendshipsBasePath = '/api/friendships';
  static String friendshipsRequestPath(String targetUsername) => '/api/friendships/request/$targetUsername';
  static String friendshipsAcceptPath(String senderUsername) => '/api/friendships/accept/$senderUsername';
  static String friendshipsRejectPath(String senderUsername) => '/api/friendships/reject/$senderUsername';
  static String friendshipsBlockPath(String targetUsername) => '/api/friendships/block/$targetUsername';
  static String friendshipsUnblockPath(String targetUsername) => '/api/friendships/unblock/$targetUsername';
  static String friendshipsUnfriendPath(String targetUsername) => '/api/friendships/unfriend/$targetUsername';
  static const String friendshipsRequestsPath = '/api/friendships/requests';

  // Conversations & Messages
  static const String conversationsBasePath = '/api/conversations';
  static String conversationByIdPath(String conversationId) => '/api/conversations/$conversationId';
  static const String messagesBasePath = '/api/messages';
  static const String messagesReplyPostPath = '/api/messages/reply-post';

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
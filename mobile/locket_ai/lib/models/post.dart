enum PostType { image, video }

class Post {
  final String id;
  final String author;
  final String filePath;
  final PostType type;
  final String? caption;
  final DateTime createdAt;

  Post({
    required this.id,
    required this.author,
    required this.filePath,
    required this.type,
    this.caption,
    required this.createdAt,
  });
}

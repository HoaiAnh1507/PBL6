import '../../models/post.dart';

class ApiService {
  static Future<List<Post>> fetchSamplePosts() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.generate(6, (i) {
      return Post(
        id: '$i',
        author: 'User${i + 1}',
        filePath: i % 2 == 0 ? 'https://picsum.photos/seed/$i/720/1280' : 'assets/videos/sample${(i % 3) + 1}.mp4',
        type: i % 2 == 0 ? PostType.image : PostType.video,
        caption: 'Caption cho post ${i + 1}',
        createdAt: DateTime.now().subtract(Duration(hours: i * 2)),
      );
    });
  }
}

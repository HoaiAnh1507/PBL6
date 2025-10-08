import 'package:flutter/material.dart';
import '../models/post.dart';
import '../core/services/api_service.dart';

class FeedViewModel extends ChangeNotifier {
  List<Post> posts = [];
  bool loading = false;

  Future<void> loadSamplePosts() async {
    loading = true;
    notifyListeners();
    posts = await ApiService.fetchSamplePosts();
    loading = false;
    notifyListeners();
  }

  void addPost(Post p) {
    posts.insert(0, p);
    notifyListeners();
  }
}

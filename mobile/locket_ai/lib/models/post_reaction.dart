import 'package:equatable/equatable.dart';
import 'post.dart';
import 'user.dart';

class PostReaction extends Equatable {
  final String reactionId;
  final Post? post;
  final User? user;
  final String emojiType;
  final DateTime createdAt;

  const PostReaction({
    required this.reactionId,
    this.post,
    this.user,
    required this.emojiType,
    required this.createdAt,
  });

  factory PostReaction.fromJson(Map<String, dynamic> json) {
    return PostReaction(
      reactionId: json['reactionId'] ?? '',
      post: json['post'] != null ? Post.fromJson(json['post']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      emojiType: json['emojiType'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reactionId': reactionId,
      'post': post?.toJson(),
      'user': user?.toJson(),
      'emojiType': emojiType,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  PostReaction copyWith({
    String? reactionId,
    Post? post,
    User? user,
    String? emojiType,
    DateTime? createdAt,
  }) {
    return PostReaction(
      reactionId: reactionId ?? this.reactionId,
      post: post ?? this.post,
      user: user ?? this.user,
      emojiType: emojiType ?? this.emojiType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [reactionId, post, user, emojiType, createdAt];
}

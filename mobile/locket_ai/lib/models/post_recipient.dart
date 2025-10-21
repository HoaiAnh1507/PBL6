import 'package:equatable/equatable.dart';
import 'post.dart';
import 'user.dart';

class PostRecipient extends Equatable {
  final String postRecipientId;
  final Post? post;
  final User? recipient;

  const PostRecipient({
    required this.postRecipientId,
    this.post,
    this.recipient,
  });

  factory PostRecipient.fromJson(Map<String, dynamic> json) {
    return PostRecipient(
      postRecipientId: json['postRecipientId'] ?? '',
      post: json['post'] != null ? Post.fromJson(json['post']) : null,
      recipient: json['recipient'] != null ? User.fromJson(json['recipient']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postRecipientId': postRecipientId,
      'post': post?.toJson(),
      'recipient': recipient?.toJson(),
    };
  }

  PostRecipient copyWith({
    String? postRecipientId,
    Post? post,
    User? recipient,
  }) {
    return PostRecipient(
      postRecipientId: postRecipientId ?? this.postRecipientId,
      post: post ?? this.post,
      recipient: recipient ?? this.recipient,
    );
  }

  @override
  List<Object?> get props => [postRecipientId, post, recipient];
}

import 'package:equatable/equatable.dart';
import 'conversation_model.dart';
import 'user_model.dart';
import 'post_model.dart';

class Message extends Equatable {
  final String messageId;
  final Conversation? conversation;
  final User? sender;
  final String content;
  final Post? repliedToPost;
  final DateTime sentAt;
  final bool read;

  const Message({
    required this.messageId,
    this.conversation,
    this.sender,
    required this.content,
    this.repliedToPost,
    required this.sentAt,
    this.read = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'] ?? '',
      conversation: json['conversation'] != null
          ? Conversation.fromJson(json['conversation'])
          : null,
      sender: json['sender'] != null ? User.fromJson(json['sender']) : null,
      content: json['content'] ?? '',
      repliedToPost: json['repliedToPost'] != null
          ? Post.fromJson(json['repliedToPost'])
          : null,
      sentAt: DateTime.parse(json['sentAt']),
      read: ((json['read'] ?? json['isRead'] ?? false) == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'conversation': conversation?.toJson(),
      'sender': sender?.toJson(),
      'content': content,
      'repliedToPost': repliedToPost?.toJson(),
      'sentAt': sentAt.toIso8601String(),
      'read': read,
    };
  }

  Message copyWith({
    String? messageId,
    Conversation? conversation,
    User? sender,
    String? content,
    Post? repliedToPost,
    DateTime? sentAt,
    bool? read,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      conversation: conversation ?? this.conversation,
      sender: sender ?? this.sender,
      content: content ?? this.content,
      repliedToPost: repliedToPost ?? this.repliedToPost,
      sentAt: sentAt ?? this.sentAt,
      read: read ?? this.read,
    );
  }

  @override
  List<Object?> get props =>
      [messageId, conversation, sender, content, repliedToPost, sentAt, read];
}

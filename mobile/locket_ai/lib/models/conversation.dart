import 'package:equatable/equatable.dart';
import 'user.dart';
import 'message.dart';

class Conversation extends Equatable {
  final String conversationId;
  final User userOne;
  final User userTwo;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final List<Message>? messages;

  const Conversation({
    required this.conversationId,
    required this.userOne,
    required this.userTwo,
    this.lastMessageAt,
    required this.createdAt,
    this.messages,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      conversationId: json['conversationId'],
      userOne: User.fromJson(json['userOne']),
      userTwo: User.fromJson(json['userTwo']),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      messages: json['messages'] != null
          ? (json['messages'] as List)
              .map((e) => Message.fromJson(e))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversationId': conversationId,
      'userOne': userOne.toJson(),
      'userTwo': userTwo.toJson(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'messages': messages?.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props =>
      [conversationId, userOne, userTwo, lastMessageAt, createdAt, messages];
}

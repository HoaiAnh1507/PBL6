import 'package:flutter/material.dart';
import 'package:locket_ai/models/message_model.dart';
import 'package:locket_ai/viewmodels/message.viewmodel.dart';
import '../models/conversation_model.dart';

class ConversationViewModel extends ChangeNotifier {
  Conversation _conversation;
  final List<MessageViewModel> _messages = [];

  ConversationViewModel(this._conversation) {
  if (_conversation.messages != null) {
      for (var msg in _conversation.messages!) {
        _messages.add(MessageViewModel(msg));
      }
    }
  }

  Conversation get conversation => _conversation;

  String get conversationId => _conversation.conversationId;
  DateTime? get lastMessageAt => _conversation.lastMessageAt;
  DateTime get createdAt => _conversation.createdAt;
  List<MessageViewModel> get messages => List.unmodifiable(_messages);

  void addMessage(Message message) {
    _conversation = _conversation.copyWith(
      messages: [...?_conversation.messages, message],
      lastMessageAt: message.sentAt,
    );
    _messages.add(MessageViewModel(message));
    notifyListeners();
  }

  void updateLastMessageAt(DateTime time) {
    _conversation = _conversation.copyWith(lastMessageAt: time);
    notifyListeners();
  }

  void markAllMessagesAsRead() {
    // ignore: unused_local_variable
    for (var msgVM in _messages) {
    // giả sử bạn thêm isRead vào Message nếu cần
    }
    notifyListeners();
  }
}

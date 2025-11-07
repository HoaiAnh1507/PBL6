import 'package:flutter/material.dart';
import '../models/message_model.dart';

class MessageViewModel extends ChangeNotifier {
  Message _message;

  MessageViewModel(this._message);

  Message get message => _message;

  String get id => _message.messageId;
  String get content => _message.content;
  DateTime get sentAt => _message.sentAt;
  bool get hasConversation => _message.conversation != null;

  void updateContent(String newContent) {
    _message = _message.copyWith(content: newContent);
    notifyListeners();
  }

  void updateConversation(Message? conversation) {
    _message = _message.copyWith(conversation: conversation?.conversation);
    notifyListeners();
  }
}

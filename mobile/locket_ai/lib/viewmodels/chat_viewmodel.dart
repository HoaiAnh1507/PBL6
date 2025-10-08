import 'package:flutter/material.dart';
import '../models/user.dart';

class ChatViewModel extends ChangeNotifier {
  List<User> friends = [
    User(id: '1', name: 'Tuan'),
    User(id: '2', name: 'Hieu'),
    User(id: '3', name: 'Rin'),
    User(id: '4', name: 'Khoi'),
  ];
}

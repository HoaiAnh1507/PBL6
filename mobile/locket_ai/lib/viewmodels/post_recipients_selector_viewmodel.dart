import 'package:flutter/foundation.dart';

class PostRecipientsSelectorViewModel extends ChangeNotifier {
  bool _allSelected = false;
  final Set<String> _selectedIds = {};

  bool get allSelected => _allSelected;
  List<String> get selectedIds => List.unmodifiable(_selectedIds);

  void toggleAll() {
    if (_allSelected) {
      _allSelected = false;
    } else {
      _allSelected = true;
      _selectedIds.clear();
    }
    notifyListeners();
  }

  void toggleFriend(String userId) {
    if (_allSelected) {
      _allSelected = false;
    }
    if (_selectedIds.contains(userId)) {
      _selectedIds.remove(userId);
    } else {
      _selectedIds.add(userId);
    }
    notifyListeners();
  }

  List<String>? recipientIdsForApi() {
    if (_allSelected) return null;
    return _selectedIds.toList();
  }
}


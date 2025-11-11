import 'package:flutter/foundation.dart';

class PostRecipientsSelectorViewModel extends ChangeNotifier {
  bool _allSelected = false;
  final Set<String> _selectedIds = {};

  bool get allSelected => _allSelected;
  List<String> get selectedIds => List.unmodifiable(_selectedIds);

  /// Bật/tắt All. Khi bật, thêm toàn bộ friendIds vào _selectedIds để gửi backend.
  void toggleAll({List<String>? friendIds}) {
    if (_allSelected) {
      _allSelected = false;
      _selectedIds.clear();
    } else {
      _allSelected = true;
      _selectedIds.clear();
      if (friendIds != null && friendIds.isNotEmpty) {
        _selectedIds.addAll(friendIds);
      }
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

  /// Trả về danh sách recipientIds để backend xử lý, gồm cả khi All được bật.
  List<String> recipientIdsForApi() {
    return _selectedIds.toList();
  }
}


import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/post_recipients_selector_viewmodel.dart';

void main() {
  group('PostRecipientsSelectorViewModel more cases', () {
    test('toggleFriend adds when not selected', () {
      final vm = PostRecipientsSelectorViewModel();
      vm.toggleFriend('x');
      expect(vm.selectedIds.contains('x'), isTrue);
    });

    test('toggleFriend twice removes back to empty', () {
      final vm = PostRecipientsSelectorViewModel();
      vm.toggleFriend('x');
      vm.toggleFriend('x');
      expect(vm.selectedIds.contains('x'), isFalse);
      expect(vm.selectedIds, isEmpty);
    });
  });
}
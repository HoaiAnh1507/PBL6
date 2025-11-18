import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/post_recipients_selector_viewmodel.dart';

void main() {
  group('PostRecipientsSelectorViewModel', () {
    test('toggleAll selects all provided friendIds', () {
      final vm = PostRecipientsSelectorViewModel();
      vm.toggleAll(friendIds: ['a','b','c']);
      expect(vm.allSelected, isTrue);
      expect(vm.selectedIds, ['a','b','c']);
      expect(vm.recipientIdsForApi(), ['a','b','c']);
    });

    test('toggleAll off clears selection', () {
      final vm = PostRecipientsSelectorViewModel();
      vm.toggleAll(friendIds: ['a','b']);
      vm.toggleAll();
      expect(vm.allSelected, isFalse);
      expect(vm.selectedIds, isEmpty);
    });

    test('toggleFriend disables allSelected and toggles entry', () {
      final vm = PostRecipientsSelectorViewModel();
      vm.toggleAll(friendIds: ['a','b']);
      vm.toggleFriend('a');
      expect(vm.allSelected, isFalse);
      expect(vm.selectedIds.contains('a'), isFalse);
      vm.toggleFriend('a');
      expect(vm.selectedIds.contains('a'), isTrue);
    });
  });
}

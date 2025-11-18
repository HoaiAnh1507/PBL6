import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/settings_viewmodel.dart';

void main() {
  group('SettingsViewModel toggles multiple times', () {
    test('notifications toggle twice returns original', () {
      final vm = SettingsViewModel();
      final original = vm.notificationsEnabled;
      vm.setNotificationsEnabled(!original);
      vm.setNotificationsEnabled(original);
      expect(vm.notificationsEnabled, original);
    });

    test('privateAccount toggle switch', () {
      final vm = SettingsViewModel();
      vm.setPrivateAccount(true);
      expect(vm.privateAccount, isTrue);
      vm.setPrivateAccount(false);
      expect(vm.privateAccount, isFalse);
    });
  });
}

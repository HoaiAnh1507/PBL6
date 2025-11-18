import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/settings_viewmodel.dart';

void main() {
  test('SettingsViewModel toggles and updates', () {
    final vm = SettingsViewModel();
    vm.setUsername('A');
    expect(vm.username, 'A');
    vm.setNotificationsEnabled(false);
    expect(vm.notificationsEnabled, isFalse);
    vm.setPrivateAccount(true);
    expect(vm.privateAccount, isTrue);
  });
}
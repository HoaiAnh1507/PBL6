import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SettingsViewModel>(context);
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(radius: 40, child: Text(vm.username.isNotEmpty ? vm.username[0] : 'U')),
            const SizedBox(height: 12),
            Center(child: Text(vm.username, style: const TextStyle(color: Colors.white, fontSize: 18))),
            const SizedBox(height: 20),
            ListTile(leading: const Icon(Icons.person), title: const Text('Hồ sơ', style: TextStyle(color: Colors.white))),
            ListTile(leading: const Icon(Icons.notifications), title: const Text('Thông báo', style: TextStyle(color: Colors.white))),
            ListTile(leading: const Icon(Icons.lock), title: const Text('Riêng tư', style: TextStyle(color: Colors.white))),
            ListTile(leading: const Icon(Icons.logout), title: const Text('Đăng xuất', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}

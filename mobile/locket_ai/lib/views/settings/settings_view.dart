import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/settings_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/friendship_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../core/constants/colors.dart';
import '../profile/profile_view.dart';
import 'package:locket_ai/widgets/async_avatar.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<SettingsViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context);
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final current = authVM.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: instagramGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AsyncAvatar(
                    url: current?.profilePictureUrl,
                    radius: 40,
                    fallbackKey: current?.userId,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    current?.fullName.isNotEmpty == true ? current!.fullName : vm.username,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  if (current != null)
                    Text(
                      '@${current.username}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle('Account'),
            _settingsCard([
              _navTile(
                context: context,
                icon: Icons.person_outline,
            title: 'Profile',
                subtitle: 'View and edit information',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProfileView(
                        currentUser: current,
                        loadProfile: () async {
                          final jwt = authVM.jwtToken;
                          if (jwt != null && jwt.isNotEmpty) {
                            await userVM.fetchOwnProfile(jwt);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
              _actionTile(
                context: context,
                icon: Icons.logout,
            title: 'Log Out',
                color: Colors.redAccent,
                onTap: () async {
                  // Xoá toàn bộ dữ liệu đã fetch của tài khoản
                  final userVM = Provider.of<UserViewModel>(context, listen: false);
                  final feedVM = Provider.of<FeedViewModel>(context, listen: false);
                  final friendshipVM = Provider.of<FriendshipViewModel>(context, listen: false);
                  final chatVM = Provider.of<ChatViewModel>(context, listen: false);

                  // Đăng xuất khỏi backend và xoá JWT/currentUser
                  await authVM.logout();

                  // Dọn sạch các ViewModel về trạng thái rỗng
                  userVM.clearAll();
                  feedVM.clearAll();
                  friendshipVM.clearAll();
                  chatVM.clearAll();

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out and cleared local data')),
                  );
                },
              ),
            ]),

            const SizedBox(height: 16),

        _sectionTitle('Options'),
            _settingsCard([
              _switchTile(
                icon: Icons.notifications_active_outlined,
            title: 'Notifications',
                value: vm.notificationsEnabled,
                onChanged: vm.setNotificationsEnabled,
              ),
              _switchTile(
                icon: Icons.lock_outline,
            title: 'Private Account',
                value: vm.privateAccount,
                onChanged: vm.setPrivateAccount,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, bottom: 10),
      child: Builder(
        builder: (context) => Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
      ),
    );
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(children: children),
    );
  }

  Widget _navTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
      subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white70),
      onTap: onTap,
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white),
      title: Builder(
        builder: (context) => Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color ?? Colors.white)),
      ),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
      title: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 12),
          Text(title, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}

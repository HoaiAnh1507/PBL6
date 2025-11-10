import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../core/constants/colors.dart';
import 'edit_profile_view.dart';

class ProfileView extends StatelessWidget {
  final User? currentUser;
  final Future<void> Function()? loadProfile;

  const ProfileView({super.key, this.currentUser, this.loadProfile});

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final userVM = Provider.of<UserViewModel>(context);
    final user = userVM.currentUser ?? currentUser ?? authVM.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              if (loadProfile != null) await loadProfile!();
            },
          )
        ],
      ),
      body: user == null
            ? Center(child: Text('No profile data', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: instagramGradient,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Colors.white24,
                        backgroundImage: (user.profilePictureUrl != null) ? NetworkImage(user.profilePictureUrl!) : null,
                        child: (user.profilePictureUrl == null)
                            ? Text(
                                (user.fullName.isNotEmpty ? user.fullName[0] : 'U'),
                                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user.fullName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('@${user.username}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70)),
                      const SizedBox(height: 10),
                      _subscriptionBadge(user.subscriptionStatus),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _infoTile('Email', user.email),
                _divider(),
                _infoTile('Phone Number', user.phoneNumber),

                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EditProfileView(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit),
                label: Text('Edit Profile', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.card,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _subscriptionBadge(SubscriptionStatus status) {
    final text = status == SubscriptionStatus.GOLD ? 'GOLD' : 'FREE';
    final color = status == SubscriptionStatus.GOLD ? Colors.amber : Colors.white54;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _infoTile(String title, String value) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      subtitle: Text(value.isNotEmpty ? value : '-', style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _divider() => const Divider(color: Colors.white12);
}
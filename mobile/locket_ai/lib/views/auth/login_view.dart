import 'package:flutter/material.dart';
import 'package:locket_ai/views/main_view.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/friendship_viewmodel.dart';
import '../../viewmodels/chat_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../viewmodels/feed_viewmodel.dart';
import 'register_view.dart';
import '../../core/constants/colors.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

  class _LoginViewState extends State<LoginView> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _signing = false;

  @override
  Widget build(BuildContext context) {
  final authVM = Provider.of<AuthViewModel>(context);
  return Scaffold(
    backgroundColor: AppColors.background,
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
            "Sign In",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                  labelText: "Email or Phone",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Enter email or phone" : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                  labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white24),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: AppColors.accent),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty ? "Enter password" : null,
                ),
                const SizedBox(height: 24),
                if (authVM.errorMessage != null)
                  Text(
                    authVM.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: (authVM.isLoading || _signing)
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() { _signing = true; });
                            final success = await authVM.login(
                              _usernameController.text.trim(),
                              _passwordController.text.trim(),
                            );

                            if (success && mounted) {
                              final friendshipVM = Provider.of<FriendshipViewModel>(context, listen: false);
                              final chatVM = Provider.of<ChatViewModel>(context, listen: false);
                              final userVM = Provider.of<UserViewModel>(context, listen: false);
                              final feedVM = Provider.of<FeedViewModel>(context, listen: false);

                              // Đồng bộ currentUser (từ backend) vào UserViewModel
                              userVM.setCurrentUser(authVM.currentUser!);

                              // Nếu có JWT: nạp friends + hội thoại từ backend
                              final jwt = authVM.jwtToken;
                              final current = authVM.currentUser!;
                              if (jwt != null && jwt.isNotEmpty) {
                                // Chạy song song friends + feed, còn chat thì nạp tuần tự: hội thoại → tin nhắn
                                await Future.wait([
                                  friendshipVM.loadFriendsRemote(jwt: jwt, current: current),
                                  friendshipVM.loadRequestsRemote(jwt: jwt, currentUserId: current.userId),
                                  feedVM.loadRemoteFeed(jwt: jwt, current: current),
                                ]);
                                await chatVM.loadRemoteConversations(jwt: jwt, currentUserId: current.userId);
                                await chatVM.prefetchLatestMessagesForAll(jwt: jwt, currentUserId: current.userId);
                              } else {
                                // Không dùng mock khi chưa có JWT. Bỏ qua nạp dữ liệu.
                              }

                              if (!mounted) return;

                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => MainView(),
                                ),
                              );
                            } else {
                              if (mounted) setState(() { _signing = false; });
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 40,
                    ),
                  ),
                  child: (authVM.isLoading || _signing)
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
            "Sign In",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterView()),
                    );
                  },
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  }
}

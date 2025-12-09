import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'viewmodels/camera_viewmodel.dart';
import 'viewmodels/feed_viewmodel.dart';
import 'viewmodels/chat_viewmodel.dart';
import 'viewmodels/settings_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/friendship_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/ai_caption_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraViewModel()),
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
        ChangeNotifierProvider(create: (_) => FriendshipViewModel()),
        ChangeNotifierProvider(create: (_) => AICaptionViewModel()),

        // ✅ FeedViewModel phụ thuộc vào UserViewModel
        ChangeNotifierProxyProvider2<UserViewModel, FriendshipViewModel, FeedViewModel>(
          create: (_) => FeedViewModel(),
          update: (_, userVM, friendshipVM, feedVM) {
            feedVM!.setDependencies(userVM, friendshipVM);
            return feedVM;
          },
        ),

        // ✅ AuthViewModel phụ thuộc vào UserViewModel
        // Giữ nguyên instance để không mất trạng thái đăng nhập
        ChangeNotifierProxyProvider<UserViewModel, AuthViewModel>(
          create: (_) => AuthViewModel(userViewModel: UserViewModel()),
          update: (_, userVM, authVM) => authVM!,
        ),

        // ✅ ChatViewModel phụ thuộc vào User + Friendship
        ChangeNotifierProxyProvider2<UserViewModel, FriendshipViewModel, ChatViewModel>(
          create: (_) => ChatViewModel(),
          update: (_, userVM, friendshipVM, chatVM) {
            chatVM ??= ChatViewModel();
            chatVM.setDependencies(userVM, friendshipVM);
            return chatVM;
          },
        ),
      ],
      child: const LocketApp(),
    ),
  );
}

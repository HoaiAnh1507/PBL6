import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../views/auth/login_view.dart';
import '../views/main_view.dart';

class LocketApp extends StatelessWidget {
  const LocketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locket AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: Consumer<AuthViewModel>(
        builder: (context, authVM, _) {
          if (authVM.isAuthenticated) {
            return const MainView();
          } else {
            return const LoginView();
          }
        },
      ),
    );
  }
}

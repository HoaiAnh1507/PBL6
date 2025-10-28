import 'package:flutter/material.dart';
import '../views/main_view.dart';

class LocketApp extends StatelessWidget {
  const LocketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Locket Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const MainView(),
    );
  }
}

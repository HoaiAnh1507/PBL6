import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';

class AsyncAvatar extends StatelessWidget {
  final String? url;
  final double radius;
  final String? fallbackKey; // e.g., userId for placeholder

  const AsyncAvatar({
    super.key,
    required this.url,
    this.radius = 32,
    this.fallbackKey,
  });

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final userVM = Provider.of<UserViewModel>(context, listen: false);
    final jwt = authVM.jwtToken;

    if (jwt == null || jwt.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white24,
        backgroundImage: (url != null && url!.isNotEmpty)
            ? NetworkImage(url!)
            : (fallbackKey != null
                ? NetworkImage('https://i.pravatar.cc/150?u=$fallbackKey')
                : null),
        child: (url == null || url!.isEmpty)
            ? const Icon(Icons.person, color: Colors.white70)
            : null,
      );
    }

    return FutureBuilder<String?>(
      future: userVM.resolveDisplayUrl(jwt: jwt, url: url),
      builder: (context, snapshot) {
        final resolved = snapshot.data ?? url;
        final imageProvider = (resolved != null && resolved.isNotEmpty)
            ? NetworkImage(resolved)
            : (fallbackKey != null
                ? NetworkImage('https://i.pravatar.cc/150?u=$fallbackKey')
                : null);
        return CircleAvatar(
          radius: radius,
          backgroundColor: Colors.white24,
          backgroundImage: imageProvider,
          child: (imageProvider == null)
              ? const Icon(Icons.person, color: Colors.white70)
              : null,
        );
      },
    );
  }
}
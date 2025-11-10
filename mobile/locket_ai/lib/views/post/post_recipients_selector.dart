import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/models/friendship_model.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/friendship_viewmodel.dart';
import '../../viewmodels/post_recipients_selector_viewmodel.dart';
import '../../models/user_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../core/constants/colors.dart';

class PostRecipientsSelector extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  const PostRecipientsSelector({super.key, this.height = 110, this.padding = const EdgeInsets.symmetric(horizontal: 16)});

  @override
  Widget build(BuildContext context) {
    final friendshipVM = Provider.of<FriendshipViewModel>(context);
    final selectorVM = Provider.of<PostRecipientsSelectorViewModel>(context);
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    final authTextStyle = GoogleFonts.poppins(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none,
    );

    // Lấy danh sách bạn bè đã chấp nhận, loại bỏ chủ tài khoản (current user)
    final current = authVM.currentUser;
    final List<User> friends;
    if (current == null) {
      friends = const [];
    } else {
      final seen = <String>{};
      friends = friendshipVM.friendships
          .where((f) => f.status == FriendshipStatus.accepted &&
              (f.userOne?.userId == current.userId || f.userTwo?.userId == current.userId))
          .map((f) => f.userOne?.userId == current.userId ? f.userTwo : f.userOne)
          .whereType<User>()
          .where((u) => u.userId != current.userId)
          .where((u) => seen.add(u.userId))
          .toList();
    }

    return SizedBox(
      height: height,
      child: Padding(
        padding: padding,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: _AllTile(
                selected: selectorVM.allSelected,
                onTap: selectorVM.toggleAll,
                labelStyle: authTextStyle,
              ),
            ),
            ...friends.map((u) => _FriendTile(
                  user: u,
                  selected: selectorVM.selectedIds.contains(u.userId),
                  onTap: () => selectorVM.toggleFriend(u.userId),
                  labelStyle: authTextStyle,
                )),
          ],
        ),
      ),
    );
  }
}

class _AllTile extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final TextStyle labelStyle;
  const _AllTile({required this.selected, required this.onTap, required this.labelStyle});

  @override
  Widget build(BuildContext context) {
    // Avatar giữ nguyên kích thước, chỉ có viền gradient khi chọn
    const double avatarSize = 52;
    const double maxRingThickness = 3.0;
    final double ringThickness = selected ? maxRingThickness : 0.0;
    // Dùng kích thước container cố định theo độ dày viền tối đa để khoảng cách luôn đều
    final double containerSize = avatarSize + maxRingThickness * 2;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: containerSize,
            height: containerSize,
            child: AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: ringThickness),
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                builder: (context, t, child) => _GradientRing(
                  size: containerSize,
                  innerSize: avatarSize,
                  thickness: t,
                  gradient: instagramGradient,
                  child: child!,
                ),
                child: const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.group, color: Colors.white, size: 28),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('All', style: labelStyle),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final User user;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle labelStyle;
  const _FriendTile({required this.user, required this.selected, required this.onTap, required this.labelStyle});

  @override
  Widget build(BuildContext context) {
    // Viền gradient giống ChatListView, chỉ hiển thị khi chọn
    final avatarProvider = (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
        ? NetworkImage(user.profilePictureUrl!)
        : null;

    // Avatar giữ nguyên kích thước, chỉ có viền gradient khi chọn
    const double avatarSize = 52;
    const double maxRingThickness = 3.0;
    final double ringThickness = selected ? maxRingThickness : 0.0;
    // Dùng kích thước container cố định theo độ dày viền tối đa để khoảng cách luôn đều
    final double containerSize = avatarSize + maxRingThickness * 2;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: containerSize,
              height: containerSize,
              child: AnimatedScale(
                scale: selected ? 1.15 : 1.0,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: ringThickness),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  builder: (context, t, child) => _GradientRing(
                    size: containerSize,
                    innerSize: avatarSize,
                    thickness: t,
                    gradient: instagramGradient,
                    child: child!,
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white12,
                    backgroundImage: avatarProvider,
                    child: avatarProvider == null
                        ? Text(
                            (user.username.isNotEmpty ? user.username[0] : '?').toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 72,
              child: Text(
                user.username,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientRing extends StatelessWidget {
  final double size;
  final double innerSize;
  final double thickness;
  final Gradient gradient;
  final Widget child;

  const _GradientRing({
    super.key,
    required this.size,
    required this.innerSize,
    required this.thickness,
    required this.gradient,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (thickness <= 0) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: SizedBox(
            width: innerSize,
            height: innerSize,
            child: ClipOval(child: child),
          ),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RingPainter(thickness: thickness, gradient: gradient),
            ),
          ),
          Center(
            child: SizedBox(
              width: size - thickness * 2,
              height: size - thickness * 2,
              child: ClipOval(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double thickness;
  final Gradient gradient;

  _RingPainter({required this.thickness, required this.gradient});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..shader = gradient.createShader(rect);

    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.shortestSide / 2) - thickness / 2;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.thickness != thickness || oldDelegate.gradient != gradient;
  }
}
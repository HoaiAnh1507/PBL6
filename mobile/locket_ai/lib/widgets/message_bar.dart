import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:locket_ai/widgets/async_avatar.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../services/posts_api.dart';

class MessageBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final FocusNode focusNode;
  final String postId;
  final bool isOwner;
  final String ownerUsername;

  const MessageBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.focusNode,
    required this.postId,
    required this.isOwner,
    required this.ownerUsername,
  });

  @override
  State<MessageBar> createState() => _MessageBarState();
}

class _MessageBarState extends State<MessageBar> with SingleTickerProviderStateMixin {
  bool _hideReactions = false;
  bool _loading = false;
  List<String> _myReactions = [];
  AnimationController? _reactFadeCtrl;
  Animation<double>? _reactOpacity;

  static const Map<String, String> emojiDisplay = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
    'care': '🤗',
    'fire': '🔥',
    'clap': '👏',
    '100': '💯',
    'star': '⭐',
    'cry_laugh': '🤣',
    'heart_broken': '💔',
    'party': '🎉',
    'mind_blown': '🤯',
  };

  final List<String> quickSet = const ['love', 'like', 'haha'];

  List<String> get allEmojis => emojiDisplay.keys.toList();
  List<String> get otherEmojis => allEmojis.where((e) => !quickSet.contains(e)).toList();

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    if (!widget.isOwner) _fetchOwnReactions();
    _reactFadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    _reactOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _reactFadeCtrl!, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    try { _reactFadeCtrl?.dispose(); } catch (_) {}
    super.dispose();
  }

  void _onFocusChange() {
    final hasFocus = widget.focusNode.hasFocus;
    if (hasFocus) {
      _reactFadeCtrl?.forward();
    } else {
      _reactFadeCtrl?.reverse();
    }
    setState(() => _hideReactions = hasFocus);
  }

  Future<void> _fetchOwnReactions() async {
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    final jwt = auth.jwtToken;
    if (jwt == null || jwt.isEmpty) return;
    try {
      final api = PostsApi(jwt: jwt);
      final res = await api.getReactions(postId: widget.postId);
      final list = (res != null && res['reaction'] is List)
          ? List<String>.from((res['reaction'] as List).map((e) => e.toString()))
          : <String>[];
      setState(() => _myReactions = list);
    } catch (_) {}
  }

  Future<void> _addReaction(String type, [Offset? origin]) async {
    _playReactionBurst(type, origin);
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    final jwt = auth.jwtToken;
    if (jwt == null || jwt.isEmpty) return;
    setState(() => _loading = true);
    try {
      final api = PostsApi(jwt: jwt);
      final updated = await api.addReaction(postId: widget.postId, emojiType: type);
      setState(() => _myReactions = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reacted to @${widget.ownerUsername}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {} finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _playReactionBurst(String type, Offset? origin) {
    final emoji = emojiDisplay[type] ?? '✨';
    final overlay = Overlay.of(context);
    if (overlay == null) return;
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => EmojiBurstOverlay(
        emoji: emoji,
        origin: origin,
        onFinished: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  Future<void> _openEmojiPicker() async {
    if (widget.isOwner) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Wrap(
            spacing: 14,
            runSpacing: 12,
            children: otherEmojis.map((type) => GestureDetector(
              onTap: () {
                Navigator.of(ctx).pop();
                _addReaction(type);
              },
              child: Text(
                emojiDisplay[type] ?? type,
                style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 26,
                      decoration: TextDecoration.none),
              ),
            )).toList(),
          ),
        );
      },
    );
  }

  Future<void> _showOwnerReactions() async {
    final auth = Provider.of<AuthViewModel>(context, listen: false);
    final jwt = auth.jwtToken;
    if (jwt == null || jwt.isEmpty) return;
    final api = PostsApi(jwt: jwt);
    final res = await api.getReactions(postId: widget.postId);
    final items = (res != null && res['users'] is List)
        ? List<Map<String, dynamic>>.from(res['users'] as List)
        : <Map<String, dynamic>>[];

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white12),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Reactions', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  )
                ],
              ),
              const Divider(color: Colors.white24),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text('No reactions yet', style: GoogleFonts.poppins(color: Colors.white70)),
                )
              else
                ...items.map((u) {
                  final username = (u['username'] ?? '').toString();
                  final fullName = (u['fullName'] ?? '').toString();
                  final reactions = (u['reactions'] is List)
                      ? List<String>.from((u['reactions'] as List).map((e) => e.toString()))
                      : <String>[];
                  final display = reactions.map((r) => emojiDisplay[r] ?? r).join('  ');
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        AsyncAvatar(
                          url: (u['profilePictureUrl'] ?? '').toString(),
                          radius: 20,
                          fallbackKey: (u['userId'] ?? username).toString(),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName.isNotEmpty ? fullName : '@$username', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16)),
                              Text('@$username', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12))
                            ],
                          ),
                        ),
                        Text(display, style: GoogleFonts.poppins(color: Colors.white, fontSize: 18))
                      ],
                    ),
                  );
                })
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOwner) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8, left: 85, right: 85),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _showOwnerReactions,
                icon: const Icon(Icons.emoji_emotions, color: Colors.white70),
                label: Text('View reactions', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        margin: const EdgeInsets.only(bottom: 8, left: 15, right: 15),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white12),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                focusNode: widget.focusNode,
                controller: widget.controller,
                autofocus: false,
                style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: "Send a message...",
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => widget.onSend(),
              ),
            ),
            const SizedBox(width: 8),
            IgnorePointer(
              ignoring: widget.focusNode.hasFocus,
              child: (_reactOpacity != null)
                  ? FadeTransition(
                opacity: _reactOpacity!,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final type in quickSet)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTapDown: (d) => _loading ? null : _addReaction(type, d.globalPosition),
                          child: Text(
                            emojiDisplay[type] ?? type,
                            style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 20,
                                decoration: TextDecoration.none),
                          ),
                        ),
                      ),
                    IconButton(
                      onPressed: _openEmojiPicker,
                      icon: const Icon(Icons.more_horiz, color: Colors.white70),
                    ),
                  ],
                ),
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final type in quickSet)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTapDown: (d) => _loading ? null : _addReaction(type, d.globalPosition),
                        child: Text(
                          emojiDisplay[type] ?? type,
                          style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              decoration: TextDecoration.none),
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: _openEmojiPicker,
                    icon: const Icon(Icons.more_horiz, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmojiBurstOverlay extends StatefulWidget {
  final String emoji;
  final Offset? origin; // global position of tap
  final VoidCallback onFinished;

  const EmojiBurstOverlay({super.key, required this.emoji, required this.origin, required this.onFinished});

  @override
  State<EmojiBurstOverlay> createState() => _EmojiBurstOverlayState();
}

class _EmojiBurstOverlayState extends State<EmojiBurstOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _dy;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();
    _opacity = CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.8, end: 1.8).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _dy = Tween<double>(begin: 0, end: -48).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.addStatusListener((st) {
      if (st == AnimationStatus.completed) {
        widget.onFinished();
        _controller.dispose();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: true,
      child: SizedBox.expand(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (ctx, _) {
            final media = MediaQuery.of(ctx);
            final top = (widget.origin?.dy ?? media.size.height * 0.85) + _dy.value;
            final left = (widget.origin?.dx ?? media.size.width * 0.8);
            return Stack(
              children: [
                Positioned(
                  top: top,
                  left: left,
                  child: Opacity(
                    opacity: 1.0 - _opacity.value,
                    child: Transform.scale(
                      scale: _scale.value,
                      child: Text(widget.emoji, 
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 28,
                          decoration: TextDecoration.none),
                        ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
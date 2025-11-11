import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:locket_ai/widgets/async_avatar.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/feed_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/friendship_viewmodel.dart';
import '../../viewmodels/user_viewmodel.dart';
import '../../models/post_model.dart';
import '../../models/friendship_model.dart';
import '../../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:locket_ai/views/camera/capture_preview_page.dart';
import 'package:locket_ai/widgets/base_header.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:locket_ai/core/constants/colors.dart';
import 'package:locket_ai/widgets/gradient_icon.dart';
import '../../core/services/camera_service.dart';
import 'camera_preview.dart';

class CameraView extends StatefulWidget {
  final PageController verticalController;
  final PageController horizontalController;
  const CameraView({super.key, required this.verticalController, required this.horizontalController});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final PageController _vCtrl;
  CameraController? _camCtrl;
  bool _cameraReady = false;
  List<CameraDescription> _cams = [];
  bool _isPressed = false;
  bool _isRecording = false;
  Timer? _recordTimer;
  final int _maxDuration = 15;
  DateTime? _pressStartTime;

  @override
  void initState() {
    super.initState();
    _vCtrl = PageController(initialPage: 0);
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (_cameraReady) return; // tránh khởi tạo lại nhiều lần

    await [Permission.camera, Permission.microphone, Permission.photos].request();

    _cams = await CameraService.available();
    if (_cams.isNotEmpty) {
      _camCtrl = CameraController(
        _cams.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      await _camCtrl!.initialize();
      if (mounted) setState(() => _cameraReady = true);
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _vCtrl.dispose();
    _camCtrl?.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();

    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 5,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.white),
            title: const Text("Choose photo", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, "image"),
            ),
            ListTile(
            leading: const Icon(Icons.video_library, color: Colors.white),
            title: const Text("Choose video", style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, "video"),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == "image") {
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null && mounted) {
        _showCaptureOverlay(picked.path, false);
      }
    } else if (choice == "video") {
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked != null && mounted) {
        _showCaptureOverlay(picked.path, true);
      }
    }
  }

  Future<void> _onCapturePressed() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    final file = await _camCtrl!.takePicture();
    if (!mounted) return;
    _showCaptureOverlay(file.path, false);
  }

  Future<void> _startRecording() async {
    if (_camCtrl == null || !_camCtrl!.value.isInitialized) return;
    try {
      await _camCtrl!.startVideoRecording();
      setState(() => _isRecording = true);

      const tick = Duration(milliseconds: 100);
      _recordTimer = Timer.periodic(tick, (timer) {
        if (timer.tick * tick.inSeconds >= _maxDuration) _stopRecording();
      });
    } catch (e) {
      debugPrint("Error starting video: $e");
    }
  }

  Future<void> _stopRecording() async {
    if (_camCtrl == null || !_isRecording) return;
    try {
      _recordTimer?.cancel();
      final file = await _camCtrl!.stopVideoRecording();
      setState(() => _isRecording = false);

      if (!mounted) return;
      _showCaptureOverlay(file.path, true);
    } catch (e) {
      debugPrint("Error stopping video: $e");
    }
  }

  void _showCaptureOverlay(String path, bool isVideo) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CapturePreviewPage(
          imagePath: path,
          isVideo: isVideo,
          onPost: (caption, mediaPath, isV) {
            final feedVm = Provider.of<FeedViewModel>(context, listen: false);
            final authVm = Provider.of<AuthViewModel>(context, listen: false);
            final user = authVm.currentUser;

            if (user != null) {
              final post = Post(
                postId: DateTime.now().millisecondsSinceEpoch.toString(),
                user: user,
                mediaType: isV ? MediaType.VIDEO : MediaType.PHOTO,
                mediaUrl: mediaPath,
                generatedCaption: null,
                captionStatus: CaptionStatus.COMPLETED,
                userEditedCaption: caption.isNotEmpty ? caption : null,
                createdAt: DateTime.now(),
              );
              feedVm.addPost(post);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isV
            ? 'Video posted (demo)'
            : 'Photo posted (demo)'),
              ),
            );
          },
        ),
      ),
    );

    // Sau khi đóng preview, chuyển thẳng sang Feed để xem bài đăng mới
    try {
      widget.verticalController.jumpToPage(1);
    } catch (_) {}

    if (_camCtrl != null && !_camCtrl!.value.isStreamingImages) {
      try {
        await _camCtrl!.initialize();
        if (mounted) setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _flipCamera() async {
    if (_cams.length < 2) return;
    final current = _cams.indexOf(_camCtrl!.description);
    final next = (current + 1) % _cams.length;
    _camCtrl = CameraController(
      _cams[next],
      ResolutionPreset.high,
      enableAudio: true,
    );
    await _camCtrl!.initialize();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PageView(
      controller: _vCtrl,
      scrollDirection: Axis.vertical,
      children: [
        _cameraReady
            ? _buildCameraStack(context)
            : const Center(
                child: CircularProgressIndicator(color: Colors.pinkAccent)),
      ],
    );
  }

  Widget _buildCameraStack(BuildContext context) {
    return Stack(
      children: [
        _buildHeader(),
        _buildCameraPreview(),
        if (_isRecording) _buildProgressBar(),
        _buildCaptureControls(),
        _buildBottomText(),
      ],
    );
  }

  Widget _buildHeader() {
    return BaseHeader(
      horizontalController: widget.horizontalController,
      count: _acceptedFriendsCount(),
      label: 'Your friends',
      onTap: _showFriendsSheet
    );
  }

  int _acceptedFriendsCount() {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    // Lắng nghe thay đổi để header cập nhật số bạn bè ngay khi state đổi
    final friendshipVM = Provider.of<FriendshipViewModel>(context);
    final current = authVM.currentUser;
    if (current == null) return 0;
    final friends = friendshipVM.friendships.where((f) =>
      f.status == FriendshipStatus.accepted &&
      (f.userOne?.userId == current.userId || f.userTwo?.userId == current.userId)
    ).map((f) => f.userOne?.userId == current.userId ? f.userTwo : f.userOne).whereType<User>();
    return friends.length;
  }

  Future<void> _showFriendsSheet() async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);
    Provider.of<UserViewModel>(context, listen: false);
    final friendshipVM = Provider.of<FriendshipViewModel>(context, listen: false);
    final current = authVM.currentUser;
    final jwt = authVM.jwtToken;

    if (current == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in.')),
      );
      return;
    }

    // Đồng bộ bạn bè đã chấp nhận và danh sách pending từ backend trước khi hiển thị
    if (jwt != null && jwt.isNotEmpty) {
      await friendshipVM.loadFriendsRemote(jwt: jwt, current: current);
      await friendshipVM.loadRequestsRemote(jwt: jwt, currentUserId: current.userId);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.95,
        child: _FriendsSheet(),
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size.width;
    return Positioned(
      top: 130,
      left: 7,
      right: 7,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: size,
              height: MediaQuery.of(context).size.height * 0.8,
              child: CameraPreviewWidget(controller: _camCtrl!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Positioned(
      bottom: 300,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(seconds: _maxDuration),
          onEnd: _stopRecording,
          builder: (_, value, __) => LinearProgressIndicator(
            value: value,
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.pinkAccent),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureControls() {
    return Positioned(
      bottom: 180,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(onTap: _pickFromGallery, child: const GradientIcon(icon: Icons.photo_library_outlined, size: 30)),
          GestureDetector(
            onTapDown: (_) {
              _pressStartTime = DateTime.now();
              _isPressed = true;
              setState(() {});
            },
            onTapUp: (_) async {
              final pressDuration =
                  DateTime.now().difference(_pressStartTime ?? DateTime.now());

              final wasLongPress = pressDuration.inMilliseconds > 300;

              setState(() => _isPressed = false);

              if (_isRecording) {
                await _stopRecording();
              } else if (wasLongPress) {
                await _startRecording();
              } else {
                await _onCapturePressed();
              }
            },
            onTapCancel: () async {
              _isPressed = false;
              setState(() {});
              if (_isRecording) await _stopRecording();
            },
            child: Container(
              height: 90,
              width: 90,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: instagramGradient),
              child: Center(
                child: AnimatedScale(
                  scale: _isPressed ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    height: 78,
                    width: 78,
                    decoration: BoxDecoration(
                      color: _isRecording ? const Color(0xFFC4C3C3) : Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(onTap: _flipCamera, child: const GradientIcon(icon: Icons.flip_camera_ios, size: 30)),
        ],
      ),
    );
  }

  Widget _buildBottomText() {
    return Positioned(
      bottom: 70,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text("History",
              style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none)),
          const GradientIcon(icon: Icons.expand_more),
        ],
      ),
    );
  }
}

// Persistent stateful sheet to keep search result when keyboard hides
class _FriendsSheet extends StatefulWidget {
  const _FriendsSheet();

  @override
  State<_FriendsSheet> createState() => _FriendsSheetState();
}

class _FriendsSheetState extends State<_FriendsSheet> {
  User? _searchResult;
  Friendship? _pendingSent;
  String _query = '';
  late final TextEditingController _searchController;
  late final FocusNode _searchFocus;
  // Guards to prevent duplicate API requests due to rapid taps
  bool _sendingRequest = false; // for search result Add/Cancel
  final Set<String> _busyFriendshipIds = {}; // for accept/reject/unfriend

  void _safeShowSnack(BuildContext ctx, String message) {
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger != null && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocus = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVM = Provider.of<AuthViewModel>(context);
    final userVM = Provider.of<UserViewModel>(context);
    final friendshipVM = Provider.of<FriendshipViewModel>(context);
    final current = authVM.currentUser!;
    final jwt = authVM.jwtToken;

    final acceptedFriends = friendshipVM.friendships.where((f) =>
      f.status == FriendshipStatus.accepted &&
      (f.userOne?.userId == current.userId || f.userTwo?.userId == current.userId)
    ).toList();
    final acceptedUsers = acceptedFriends.map((f) => f.userOne?.userId == current.userId ? f.userTwo! : f.userOne!).toList();

    Future<void> _doSearch(String q) async {
      _query = q.trim();
      if (_query.isEmpty) {
        setState(() {
          _searchResult = null;
          _pendingSent = null;
        });
        return;
      }
      if (jwt == null || jwt.isEmpty) {
    _safeShowSnack(context, 'Missing JWT. Please log in to find new friends.');
        return;
      }
      final results = await userVM.searchUsers(jwt: jwt, query: _query);
      final exact = results.where((u) => u.username == _query).toList();
      if (exact.isEmpty) {
        setState(() {
          _searchResult = null;
          _pendingSent = null;
        });
      } else {
        final candidate = exact.first;
        final isSelf = candidate.userId == current.userId || candidate.username == current.username;
        final alreadyFriend = acceptedUsers.any((u) => u.userId == candidate.userId);
        if (isSelf || alreadyFriend) {
          setState(() {
            _searchResult = null;
            _pendingSent = null;
          });
        } else {
          final pending = friendshipVM.friendships.firstWhere(
            (f) => f.status == FriendshipStatus.pending && f.userOne?.userId == current.userId && f.userTwo?.userId == candidate.userId,
            orElse: () => Friendship(friendshipId: '', userOne: null, userTwo: null, status: FriendshipStatus.pending, createdAt: DateTime.now()),
          );
          setState(() {
            _searchResult = candidate;
            _pendingSent = pending.friendshipId.isEmpty ? null : pending;
          });
        }
      }
    }

    final incomingRequests = friendshipVM.friendships.where((f) =>
      f.status == FriendshipStatus.pending && f.userTwo?.userId == current.userId
    ).toList();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Your friends',
                  style: GoogleFonts.poppins(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  acceptedUsers.isNotEmpty
                      ? 'There are ${acceptedUsers.length} beside you'
                      : 'You are alone :(',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 10),
                    const Icon(Icons.search, color: Colors.white70),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Add a new friend',
                          hintStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 15),
                          border: InputBorder.none,
                        ),
                        textInputAction: TextInputAction.search,
                        onChanged: _doSearch,
                        onSubmitted: _doSearch,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              if (_searchResult != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(1.2),
                    decoration: const BoxDecoration(gradient: instagramGradient, shape: BoxShape.circle),
                    child: AsyncAvatar(
                      url: _searchResult!.profilePictureUrl,
                      radius: 24,
                      fallbackKey: _searchResult!.userId,
                    ),
                  ),
                  title: Text(_searchResult!.fullName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('@${_searchResult!.username}', style: GoogleFonts.poppins(color: Colors.white70)),
                  trailing: GestureDetector(
                    onTap: () async {
                      if (_sendingRequest) return; // prevent duplicate taps
                      if (jwt == null || jwt.isEmpty) {
    _safeShowSnack(context, 'Missing JWT. Please log in again.');
                        return;
                      }
                      setState(() => _sendingRequest = true);
                      try {
                        if (_pendingSent != null) {
                          final ok = await friendshipVM.cancelSentRequestRemote(jwt: jwt, from: current, to: _searchResult!);
                          if (!ok) {
    _safeShowSnack(context, 'Backend does not support canceling sent requests yet');
                          }
                          setState(() => _pendingSent = null);
                        } else {
                          final ok = await friendshipVM.sendFriendRequestRemote(jwt: jwt, from: current, to: _searchResult!);
                          if (!ok) {
    _safeShowSnack(context, 'Failed to send friend request.');
                          }
                          final last = friendshipVM.friendships.lastWhere(
                            (f) => f.status == FriendshipStatus.pending && f.userOne?.userId == current.userId && f.userTwo?.userId == _searchResult!.userId,
                            orElse: () => Friendship(friendshipId: '', userOne: null, userTwo: null, status: FriendshipStatus.pending, createdAt: DateTime.now()),
                          );
                          setState(() => _pendingSent = last.friendshipId.isEmpty ? null : last);
                        }
                      } finally {
                        if (mounted) setState(() => _sendingRequest = false);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        _sendingRequest
                            ? (_pendingSent != null ? 'Cancelling...' : 'Sending...')
                            : (_pendingSent != null ? 'Sent' : 'Add'),
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 8),
              if (incomingRequests.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Incoming requests', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                ),
              ...incomingRequests.map((f) {
                final fromUser = f.userOne!;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(1.2),
                    decoration: const BoxDecoration(gradient: instagramGradient, shape: BoxShape.circle),
                    child: AsyncAvatar(
                      url: fromUser.profilePictureUrl,
                      radius: 24,
                      fallbackKey: fromUser.userId,
                    ),
                  ),
                  title: Text(fromUser.fullName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('@${fromUser.username}', style: GoogleFonts.poppins(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (_busyFriendshipIds.contains(f.friendshipId)) return; // prevent duplicate accepts
                          if (jwt == null || jwt.isEmpty) {
    _safeShowSnack(context, 'Missing JWT. Please log in again.');
                            return;
                          }
                          // Optimistic: move to accepted immediately
                          _busyFriendshipIds.add(f.friendshipId);
                          try {
                            friendshipVM.updateFriendshipStatus(f.friendshipId, FriendshipStatus.accepted);
                            final ok = await friendshipVM.acceptFriendRequestRemote(jwt: jwt, pending: f, current: current);
                            if (!ok) {
                              // Revert to pending on failure
                              friendshipVM.updateFriendshipStatus(f.friendshipId, FriendshipStatus.pending);
    _safeShowSnack(context, 'Failed to accept friend request.');
                            }
                          } finally {
                            _busyFriendshipIds.remove(f.friendshipId);
                          }
                        },
                      child: Container(
                        width: 34,
                        height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.greenAccent, width: 1.5),
                          ),
                          child: const Icon(Icons.check, color: Colors.greenAccent, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          if (_busyFriendshipIds.contains(f.friendshipId)) return; // prevent duplicate rejects
                          if (jwt == null || jwt.isEmpty) {
    _safeShowSnack(context, 'Missing JWT. Please log in again.');
                            return;
                          }
                          // Optimistic: remove from incoming immediately
                          _busyFriendshipIds.add(f.friendshipId);
                          try {
                            friendshipVM.removeFriendship(f.friendshipId);
                            final ok = await friendshipVM.rejectFriendRequestRemote(jwt: jwt, pending: f, current: current);
                            if (!ok) {
    _safeShowSnack(context, 'Failed to reject request. Resync...');
                              // Resync from backend to restore correct state
                              await friendshipVM.loadRequestsRemote(jwt: jwt, currentUserId: current.userId);
                            }
                          } finally {
                            _busyFriendshipIds.remove(f.friendshipId);
                          }
                        },
                      child: Container(
                        width: 34,
                        height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.pinkAccent, width: 1.5),
                          ),
                          child: const Icon(Icons.close, color: Colors.pinkAccent, size: 20),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),

              const SizedBox(height: 6),
              if (acceptedUsers.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('Friends', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
                ),
              ...acceptedFriends.map((f) {
                final friend = f.userOne?.userId == current.userId ? f.userTwo! : f.userOne!;
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(1.2),
                    decoration: const BoxDecoration(gradient: instagramGradient, shape: BoxShape.circle),
                    child: AsyncAvatar(
                      url: friend.profilePictureUrl,
                      radius: 24,
                      fallbackKey: friend.userId,
                    ),
                  ),
                  title: Text(friend.fullName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text('@${friend.username}', style: GoogleFonts.poppins(color: Colors.white70)),
                  trailing: GestureDetector(
                    onTap: () async {
                      if (_busyFriendshipIds.contains(f.friendshipId)) return; // prevent duplicate unfriend
                      if (jwt == null || jwt.isEmpty) {
    _safeShowSnack(context, 'Missing JWT. Please log in again.');
                        return;
                      }
                      _busyFriendshipIds.add(f.friendshipId);
                      try {
                        final ok = await friendshipVM.unfriendRemote(jwt: jwt, current: current, target: friend);
                        if (!ok) {
    _safeShowSnack(context, 'Failed to unfriend.');
                        }
                        setState(() {});
                      } finally {
                        _busyFriendshipIds.remove(f.friendshipId);
                      }
                    },
                    child: const Icon(Icons.close, color: Colors.white70),
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

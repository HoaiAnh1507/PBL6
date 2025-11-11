import 'package:equatable/equatable.dart';
import 'user_model.dart';

enum MediaType { PHOTO, VIDEO }
enum CaptionStatus { PENDING, COMPLETED, FAILED }

class Post extends Equatable {
  final String postId;
  final User user;
  final MediaType mediaType;
  final String mediaUrl;
  final String? generatedCaption;
  final CaptionStatus captionStatus;
  final String? userEditedCaption;
  final DateTime createdAt;

  const Post({
    required this.postId,
    required this.user,
    required this.mediaType,
    required this.mediaUrl,
    this.generatedCaption,
    required this.captionStatus,
    this.userEditedCaption,
    required this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    final createdStr = json['createdAt']?.toString() ?? DateTime.now().toIso8601String();
    final captionText = (json['generatedCaption'] ?? json['caption'])?.toString();
    return Post(
      postId: (json['postId'] ?? json['id'] ?? '').toString(),
      user: User.fromJson((json['user'] ?? const {}) as Map<String, dynamic>),
      mediaType: MediaType.values.firstWhere(
        (e) => e.name == ((json['mediaType'] ?? 'PHOTO').toString()),
        orElse: () => MediaType.PHOTO,
      ),
      mediaUrl: (json['mediaUrl'] ?? json['url'] ?? json['contentUrl'] ?? '').toString(),
      generatedCaption: captionText,
      captionStatus: CaptionStatus.values.firstWhere(
        (e) => e.name == ((json['captionStatus'] ?? 'PENDING').toString()),
        orElse: () => CaptionStatus.PENDING,
      ),
      userEditedCaption: json['userEditedCaption']?.toString(),
      createdAt: DateTime.tryParse(createdStr) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'user': user.toJson(),
      'mediaType': mediaType.name,
      'mediaUrl': mediaUrl,
      'generatedCaption': generatedCaption,
      'captionStatus': captionStatus.name,
      'userEditedCaption': userEditedCaption,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        postId,
        user,
        mediaType,
        mediaUrl,
        generatedCaption,
        captionStatus,
        userEditedCaption,
        createdAt,
      ];
}

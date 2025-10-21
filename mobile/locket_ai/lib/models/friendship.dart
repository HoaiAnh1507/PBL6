import 'package:equatable/equatable.dart';
import 'user.dart';

enum FriendshipStatus { pending, accepted, blocked }

class Friendship extends Equatable {
  final String friendshipId;
  final User? userOne;
  final User? userTwo;
  final FriendshipStatus status;
  final DateTime createdAt;

  const Friendship({
    required this.friendshipId,
    this.userOne,
    this.userTwo,
    required this.status,
    required this.createdAt,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      friendshipId: json['friendshipId'] ?? '',
      userOne:
          json['userOne'] != null ? User.fromJson(json['userOne']) : null,
      userTwo:
          json['userTwo'] != null ? User.fromJson(json['userTwo']) : null,
      status: _statusFromString(json['status']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'friendshipId': friendshipId,
      'userOne': userOne?.toJson(),
      'userTwo': userTwo?.toJson(),
      'status': status.name.toUpperCase(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Friendship copyWith({
    String? friendshipId,
    User? userOne,
    User? userTwo,
    FriendshipStatus? status,
    DateTime? createdAt,
  }) {
    return Friendship(
      friendshipId: friendshipId ?? this.friendshipId,
      userOne: userOne ?? this.userOne,
      userTwo: userTwo ?? this.userTwo,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static FriendshipStatus _statusFromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'ACCEPTED':
        return FriendshipStatus.accepted;
      case 'BLOCKED':
        return FriendshipStatus.blocked;
      default:
        return FriendshipStatus.pending;
    }
  }

  @override
  List<Object?> get props => [friendshipId, userOne, userTwo, status, createdAt];
}

import 'package:equatable/equatable.dart';

enum SubscriptionStatus { FREE, GOLD }
enum AccountStatus { ACTIVE, SUSPENDED, BANNED }

class User extends Equatable {
  final String userId;
  final String phoneNumber;
  final String username;
  final String email;
  final String fullName;
  final String? profilePictureUrl;
  final String passwordHash;
  final SubscriptionStatus subscriptionStatus;
  final DateTime? subscriptionExpiresAt;
  final AccountStatus accountStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.userId,
    required this.phoneNumber,
    required this.username,
    required this.email,
    required this.fullName,
    this.profilePictureUrl,
    required this.passwordHash,
    required this.subscriptionStatus,
    this.subscriptionExpiresAt,
    required this.accountStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'],
      phoneNumber: json['phoneNumber'],
      username: json['username'],
      email: json['email'],
      fullName: json['fullName'],
      profilePictureUrl: json['profilePictureUrl'],
      passwordHash: json['passwordHash'],
      subscriptionStatus: SubscriptionStatus.values.firstWhere(
        (e) => e.name == (json['subscriptionStatus'] ?? 'FREE'),
        orElse: () => SubscriptionStatus.FREE,
      ),
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.parse(json['subscriptionExpiresAt'])
          : null,
      accountStatus: AccountStatus.values.firstWhere(
        (e) => e.name == (json['accountStatus'] ?? 'ACTIVE'),
        orElse: () => AccountStatus.ACTIVE,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'phoneNumber': phoneNumber,
      'username': username,
      'email': email,
      'fullName': fullName,
      'profilePictureUrl': profilePictureUrl,
      'passwordHash': passwordHash,
      'subscriptionStatus': subscriptionStatus.name,
      'subscriptionExpiresAt': subscriptionExpiresAt?.toIso8601String(),
      'accountStatus': accountStatus.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        userId,
        phoneNumber,
        username,
        email,
        fullName,
        profilePictureUrl,
        passwordHash,
        subscriptionStatus,
        subscriptionExpiresAt,
        accountStatus,
        createdAt,
        updatedAt,
      ];
}

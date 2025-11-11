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
    final createdStr = json['createdAt']?.toString() ?? DateTime.now().toIso8601String();
    final updatedStr = json['updatedAt']?.toString() ?? createdStr;
    return User(
      userId: (json['userId'] ?? json['id'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['username'] ?? '').toString(),
      profilePictureUrl: json['profilePictureUrl']?.toString(),
      passwordHash: (json['passwordHash'] ?? '').toString(),
      subscriptionStatus: SubscriptionStatus.values.firstWhere(
        (e) => e.name == ((json['subscriptionStatus'] ?? 'FREE').toString()),
        orElse: () => SubscriptionStatus.FREE,
      ),
      subscriptionExpiresAt: json['subscriptionExpiresAt'] != null
          ? DateTime.tryParse(json['subscriptionExpiresAt'].toString())
          : null,
      accountStatus: AccountStatus.values.firstWhere(
        (e) => e.name == ((json['accountStatus'] ?? 'ACTIVE').toString()),
        orElse: () => AccountStatus.ACTIVE,
      ),
      createdAt: DateTime.tryParse(createdStr) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedStr) ?? DateTime.tryParse(createdStr) ?? DateTime.now(),
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

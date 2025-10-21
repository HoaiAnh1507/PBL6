import 'package:equatable/equatable.dart';
import 'package:locket_ai/models/admin_action_log.dart';
import 'package:locket_ai/models/moderation_report.dart';

class Admin extends Equatable {
  final String? adminId;
  final String email;
  final String passwordHash;
  final String? fullName;
  final DateTime? createdAt;
  final List<AdminActionLog>? actionLogs;
  final List<ModerationReport>? resolvedReports;

  const Admin({
    this.adminId,
    required this.email,
    required this.passwordHash,
    this.fullName,
    this.createdAt,
    this.actionLogs,
    this.resolvedReports,
  });

  factory Admin.fromJson(Map<String, dynamic> json) => Admin(
        adminId: json['adminId'] as String?,
        email: json['email'] as String,
        passwordHash: json['passwordHash'] as String,
        fullName: json['fullName'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        actionLogs: json['actionLogs'] != null
            ? List<AdminActionLog>.from(json['actionLogs'])
            : null,
        resolvedReports: json['resolvedReports'] != null
            ? List<ModerationReport>.from(json['resolvedReports'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'adminId': adminId,
        'email': email,
        'passwordHash': passwordHash,
        'fullName': fullName,
        'createdAt': createdAt?.toIso8601String(),
        'actionLogs': actionLogs,
        'resolvedReports': resolvedReports,
      };

  Admin copyWith({
    String? adminId,
    String? email,
    String? passwordHash,
    String? fullName,
    DateTime? createdAt,
    List<AdminActionLog>? actionLogs,
    List<ModerationReport>? resolvedReports,
  }) {
    return Admin(
      adminId: adminId ?? this.adminId,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName ?? this.fullName,
      createdAt: createdAt ?? this.createdAt,
      actionLogs: actionLogs ?? this.actionLogs,
      resolvedReports: resolvedReports ?? this.resolvedReports,
    );
  }

  @override
  List<Object?> get props =>
      [adminId, email, passwordHash, fullName, createdAt, actionLogs, resolvedReports];
}

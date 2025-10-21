import 'admin.dart';

class AdminActionLog {
  final int? logId;
  final Admin? admin;
  final String actionType;
  final String? targetId;
  final String? reason;
  final DateTime? actionTimestamp;

  const AdminActionLog({
    this.logId,
    this.admin,
    required this.actionType,
    this.targetId,
    this.reason,
    this.actionTimestamp,
  });

  factory AdminActionLog.fromJson(Map<String, dynamic> json) => AdminActionLog(
        logId: json['logId'] is int
            ? json['logId']
            : int.tryParse(json['logId'].toString()),
        admin: json['admin'] != null ? Admin.fromJson(json['admin']) : null,
        actionType: json['actionType'] as String,
        targetId: json['targetId'] as String?,
        reason: json['reason'] as String?,
        actionTimestamp: json['actionTimestamp'] != null
            ? DateTime.parse(json['actionTimestamp'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'logId': logId,
        'admin': admin?.toJson(),
        'actionType': actionType,
        'targetId': targetId,
        'reason': reason,
        'actionTimestamp': actionTimestamp?.toIso8601String(),
      };

  AdminActionLog copyWith({
    int? logId,
    Admin? admin,
    String? actionType,
    String? targetId,
    String? reason,
    DateTime? actionTimestamp,
  }) {
    return AdminActionLog(
      logId: logId ?? this.logId,
      admin: admin ?? this.admin,
      actionType: actionType ?? this.actionType,
      targetId: targetId ?? this.targetId,
      reason: reason ?? this.reason,
      actionTimestamp: actionTimestamp ?? this.actionTimestamp,
    );
  }
}

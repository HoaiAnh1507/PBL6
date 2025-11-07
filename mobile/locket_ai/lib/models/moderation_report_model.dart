import 'admin_model.dart';
import 'user_model.dart';
import 'post_model.dart';

enum ReportStatus { PENDING, RESOLVED, DISMISSED }

class ModerationReport {
  final String? reportId;
  final User? reporter;
  final Post? reportedPost;
  final User? reportedUser;
  final String? reason;
  final ReportStatus? status;
  final Admin? resolvedByAdmin;
  final String? resolutionNotes;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  const ModerationReport({
    this.reportId,
    this.reporter,
    this.reportedPost,
    this.reportedUser,
    this.reason,
    this.status,
    this.resolvedByAdmin,
    this.resolutionNotes,
    this.createdAt,
    this.resolvedAt,
  });

  factory ModerationReport.fromJson(Map<String, dynamic> json) {
    return ModerationReport(
      reportId: json['reportId'] as String?,
      reporter: json['reporter'] != null ? User.fromJson(json['reporter']) : null,
      reportedPost: json['reportedPost'] != null ? Post.fromJson(json['reportedPost']) : null,
      reportedUser: json['reportedUser'] != null ? User.fromJson(json['reportedUser']) : null,
      reason: json['reason'] as String?,
      status: json['status'] != null
          ? ReportStatus.values.firstWhere(
              (e) => e.name.toUpperCase() == json['status'].toString().toUpperCase(),
              orElse: () => ReportStatus.PENDING,
            )
          : ReportStatus.PENDING,
      resolvedByAdmin: json['resolvedByAdmin'] != null ? Admin.fromJson(json['resolvedByAdmin']) : null,
      resolutionNotes: json['resolutionNotes'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'reportId': reportId,
        'reporter': reporter?.toJson(),
        'reportedPost': reportedPost?.toJson(),
        'reportedUser': reportedUser?.toJson(),
        'reason': reason,
        'status': status?.name,
        'resolvedByAdmin': resolvedByAdmin?.toJson(),
        'resolutionNotes': resolutionNotes,
        'createdAt': createdAt?.toIso8601String(),
        'resolvedAt': resolvedAt?.toIso8601String(),
      };

  ModerationReport copyWith({
    String? reportId,
    User? reporter,
    Post? reportedPost,
    User? reportedUser,
    String? reason,
    ReportStatus? status,
    Admin? resolvedByAdmin,
    String? resolutionNotes,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return ModerationReport(
      reportId: reportId ?? this.reportId,
      reporter: reporter ?? this.reporter,
      reportedPost: reportedPost ?? this.reportedPost,
      reportedUser: reportedUser ?? this.reportedUser,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      resolvedByAdmin: resolvedByAdmin ?? this.resolvedByAdmin,
      resolutionNotes: resolutionNotes ?? this.resolutionNotes,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

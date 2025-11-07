package com.pbl6.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.GenericGenerator;
import java.time.LocalDateTime;

@Entity
@Table(name = "Moderation_Reports", indexes = {
    @Index(name = "idx_moderation_reporter_id", columnList = "reporter_id"),
    @Index(name = "idx_moderation_reported_post_id", columnList = "reported_post_id"),
    @Index(name = "idx_moderation_reported_user_id", columnList = "reported_user_id"),
    @Index(name = "idx_moderation_status", columnList = "status"),
    @Index(name = "idx_moderation_created_at", columnList = "created_at"),
    @Index(name = "idx_moderation_reviewed_by", columnList = "reviewed_by")
})
public class ModerationReport {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "report_id", length = 36)
    private String reportId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reporter_id", nullable = false)
    private User reporter;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reported_post_id")
    private Post reportedPost;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "reported_user_id")
    private User reportedUser;
    
    @Column(name = "reason", columnDefinition = "TEXT")
    private String reason;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private ReportStatus status = ReportStatus.PENDING;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "resolved_by_admin_id")
    private Admin resolvedByAdmin;
    
    @Column(name = "resolution_notes", columnDefinition = "TEXT")
    private String resolutionNotes;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "resolved_at")
    private LocalDateTime resolvedAt;
    
    public enum ReportStatus {
        PENDING, RESOLVED, DISMISSED
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Constructors
    public ModerationReport() {}
    
    public ModerationReport(User reporter, String reason) {
        this.reporter = reporter;
        this.reason = reason;
    }
    
    public ModerationReport(User reporter, Post reportedPost, String reason) {
        this.reporter = reporter;
        this.reportedPost = reportedPost;
        this.reason = reason;
    }
    
    public ModerationReport(User reporter, User reportedUser, String reason) {
        this.reporter = reporter;
        this.reportedUser = reportedUser;
        this.reason = reason;
    }
    
    // Getters and Setters
    public String getReportId() {
        return reportId;
    }
    
    public void setReportId(String reportId) {
        this.reportId = reportId;
    }
    
    public User getReporter() {
        return reporter;
    }
    
    public void setReporter(User reporter) {
        this.reporter = reporter;
    }
    
    public Post getReportedPost() {
        return reportedPost;
    }
    
    public void setReportedPost(Post reportedPost) {
        this.reportedPost = reportedPost;
    }
    
    public User getReportedUser() {
        return reportedUser;
    }
    
    public void setReportedUser(User reportedUser) {
        this.reportedUser = reportedUser;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
    
    public ReportStatus getStatus() {
        return status;
    }
    
    public void setStatus(ReportStatus status) {
        this.status = status;
    }
    
    public Admin getResolvedByAdmin() {
        return resolvedByAdmin;
    }
    
    public void setResolvedByAdmin(Admin resolvedByAdmin) {
        this.resolvedByAdmin = resolvedByAdmin;
    }
    
    public String getResolutionNotes() {
        return resolutionNotes;
    }
    
    public void setResolutionNotes(String resolutionNotes) {
        this.resolutionNotes = resolutionNotes;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getResolvedAt() {
        return resolvedAt;
    }
    
    public void setResolvedAt(LocalDateTime resolvedAt) {
        this.resolvedAt = resolvedAt;
    }
}
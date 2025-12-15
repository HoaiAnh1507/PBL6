package com.pbl6.backend.response;

import com.pbl6.backend.model.ModerationReport;
import java.time.LocalDateTime;

public class ReportResponse {
    
    private String reportId;
    private PublicUserResponse reporter;
    private PostResponse reportedPost;
    private PublicUserResponse reportedUser;
    private String reason;
    private String status;
    private String resolutionNotes;
    private LocalDateTime createdAt;
    private LocalDateTime resolvedAt;
    
    // Constructors
    public ReportResponse() {}
    
    public ReportResponse(ModerationReport report) {
        this.reportId = report.getReportId();
        if (report.getReporter() != null) {
            this.reporter = new PublicUserResponse();
            this.reporter.setUserId(report.getReporter().getUserId());
            this.reporter.setUsername(report.getReporter().getUsername());
            this.reporter.setFullName(report.getReporter().getFullName());
            this.reporter.setProfilePictureUrl(report.getReporter().getProfilePictureUrl());
        }
        if (report.getReportedPost() != null) {
            this.reportedPost = new PostResponse(report.getReportedPost());
        }
        if (report.getReportedUser() != null) {
            this.reportedUser = new PublicUserResponse();
            this.reportedUser.setUserId(report.getReportedUser().getUserId());
            this.reportedUser.setUsername(report.getReportedUser().getUsername());
            this.reportedUser.setFullName(report.getReportedUser().getFullName());
            this.reportedUser.setProfilePictureUrl(report.getReportedUser().getProfilePictureUrl());
        }
        this.reason = report.getReason();
        this.status = report.getStatus().toString();
        this.resolutionNotes = report.getResolutionNotes();
        this.createdAt = report.getCreatedAt();
        this.resolvedAt = report.getResolvedAt();
    }
    
    // Getters and Setters
    public String getReportId() {
        return reportId;
    }
    
    public void setReportId(String reportId) {
        this.reportId = reportId;
    }
    
    public PublicUserResponse getReporter() {
        return reporter;
    }
    
    public void setReporter(PublicUserResponse reporter) {
        this.reporter = reporter;
    }
    
    public PostResponse getReportedPost() {
        return reportedPost;
    }
    
    public void setReportedPost(PostResponse reportedPost) {
        this.reportedPost = reportedPost;
    }
    
    public PublicUserResponse getReportedUser() {
        return reportedUser;
    }
    
    public void setReportedUser(PublicUserResponse reportedUser) {
        this.reportedUser = reportedUser;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
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

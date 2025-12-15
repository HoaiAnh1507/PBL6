package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class ReportCreateRequest {
    
    // Either reportedPostId or reportedUserId must be provided
    // If reportedPostId is provided, reportedUserId will be auto-extracted from the post
    private String reportedPostId;
    
    private String reportedUserId; // Optional if reportedPostId is provided
    
    @NotBlank(message = "Reason is required")
    private String reason;
    
    // Constructors
    public ReportCreateRequest() {}
    
    public ReportCreateRequest(String reportedPostId, String reportedUserId, String reason) {
        this.reportedPostId = reportedPostId;
        this.reportedUserId = reportedUserId;
        this.reason = reason;
    }
    
    // Getters and Setters
    public String getReportedPostId() {
        return reportedPostId;
    }
    
    public void setReportedPostId(String reportedPostId) {
        this.reportedPostId = reportedPostId;
    }
    
    public String getReportedUserId() {
        return reportedUserId;
    }
    
    public void setReportedUserId(String reportedUserId) {
        this.reportedUserId = reportedUserId;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
}

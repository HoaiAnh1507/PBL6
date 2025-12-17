package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

public class ResolveReportRequest {
    
    @NotBlank(message = "Action is required")
    private String action; // RESOLVED or DISMISSED
    
    @NotBlank(message = "Resolution notes is required")
    private String resolutionNotes;
    
    // Constructors
    public ResolveReportRequest() {}
    
    public ResolveReportRequest(String action, String resolutionNotes) {
        this.action = action;
        this.resolutionNotes = resolutionNotes;
    }
    
    // Getters and Setters
    public String getAction() {
        return action;
    }
    
    public void setAction(String action) {
        this.action = action;
    }
    
    public String getResolutionNotes() {
        return resolutionNotes;
    }
    
    public void setResolutionNotes(String resolutionNotes) {
        this.resolutionNotes = resolutionNotes;
    }
}

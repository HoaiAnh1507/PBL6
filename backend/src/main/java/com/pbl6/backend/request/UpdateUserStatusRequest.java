package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

public class UpdateUserStatusRequest {
    
    @NotBlank(message = "Status is required")
    private String status; // ACTIVE, SUSPENDED, BANNED
    
    @NotBlank(message = "Reason is required")
    private String reason;
    
    // Constructors
    public UpdateUserStatusRequest() {}
    
    public UpdateUserStatusRequest(String status, String reason) {
        this.status = status;
        this.reason = reason;
    }
    
    // Getters and Setters
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
}

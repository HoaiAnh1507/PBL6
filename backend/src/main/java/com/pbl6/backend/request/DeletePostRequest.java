package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

public class DeletePostRequest {
    
    @NotBlank(message = "Reason is required")
    private String reason;
    
    // Constructors
    public DeletePostRequest() {}
    
    public DeletePostRequest(String reason) {
        this.reason = reason;
    }
    
    // Getters and Setters
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
}

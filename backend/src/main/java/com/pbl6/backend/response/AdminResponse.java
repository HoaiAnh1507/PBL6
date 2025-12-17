package com.pbl6.backend.response;

import com.pbl6.backend.model.Admin;
import java.time.LocalDateTime;

public class AdminResponse {
    
    private String adminId;
    private String email;
    private String fullName;
    private LocalDateTime createdAt;
    
    // Constructors
    public AdminResponse() {}
    
    public AdminResponse(Admin admin) {
        this.adminId = admin.getAdminId();
        this.email = admin.getEmail();
        this.fullName = admin.getFullName();
        this.createdAt = admin.getCreatedAt();
    }
    
    // Getters and Setters
    public String getAdminId() {
        return adminId;
    }
    
    public void setAdminId(String adminId) {
        this.adminId = adminId;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}

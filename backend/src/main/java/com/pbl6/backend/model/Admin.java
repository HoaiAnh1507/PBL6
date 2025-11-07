package com.pbl6.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.GenericGenerator;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "Admins", indexes = {
    @Index(name = "idx_admin_email", columnList = "email"),
    @Index(name = "idx_admin_created_at", columnList = "created_at")
})
public class Admin {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "admin_id", length = 36)
    private String adminId;
    
    @Column(name = "email", length = 100, nullable = false, unique = true)
    private String email;
    
    @Column(name = "password_hash", columnDefinition = "TEXT", nullable = false)
    private String passwordHash;
    
    @Column(name = "full_name", length = 100)
    private String fullName;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    // Relationships
    @OneToMany(mappedBy = "admin", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<AdminActionLog> actionLogs;
    
    @OneToMany(mappedBy = "resolvedByAdmin", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<ModerationReport> resolvedReports;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Constructors
    public Admin() {}
    
    public Admin(String email, String passwordHash, String fullName) {
        this.email = email;
        this.passwordHash = passwordHash;
        this.fullName = fullName;
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
    
    public String getPasswordHash() {
        return passwordHash;
    }
    
    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
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
    
    public List<AdminActionLog> getActionLogs() {
        return actionLogs;
    }
    
    public void setActionLogs(List<AdminActionLog> actionLogs) {
        this.actionLogs = actionLogs;
    }
    
    public List<ModerationReport> getResolvedReports() {
        return resolvedReports;
    }
    
    public void setResolvedReports(List<ModerationReport> resolvedReports) {
        this.resolvedReports = resolvedReports;
    }
}
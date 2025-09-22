package com.pbl6.backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "Admin_Actions_Log", indexes = {
    @Index(name = "idx_admin_action_admin_id", columnList = "admin_id"),
    @Index(name = "idx_admin_action_type", columnList = "action_type"),
    @Index(name = "idx_admin_action_timestamp", columnList = "action_timestamp"),
    @Index(name = "idx_admin_action_target_id", columnList = "target_id"),
    @Index(name = "idx_admin_action_admin_timestamp", columnList = "admin_id, action_timestamp")
})
public class AdminActionLog {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "log_id")
    private Long logId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "admin_id", nullable = false)
    private Admin admin;
    
    @Column(name = "action_type", length = 50, nullable = false)
    private String actionType;
    
    @Column(name = "target_id", length = 255)
    private String targetId;
    
    @Column(name = "reason", columnDefinition = "TEXT")
    private String reason;
    
    @Column(name = "action_timestamp", nullable = false, updatable = false)
    private LocalDateTime actionTimestamp;
    
    @PrePersist
    protected void onCreate() {
        actionTimestamp = LocalDateTime.now();
    }
    
    // Constructors
    public AdminActionLog() {}
    
    public AdminActionLog(Admin admin, String actionType, String targetId, String reason) {
        this.admin = admin;
        this.actionType = actionType;
        this.targetId = targetId;
        this.reason = reason;
    }
    
    // Getters and Setters
    public Long getLogId() {
        return logId;
    }
    
    public void setLogId(Long logId) {
        this.logId = logId;
    }
    
    public Admin getAdmin() {
        return admin;
    }
    
    public void setAdmin(Admin admin) {
        this.admin = admin;
    }
    
    public String getActionType() {
        return actionType;
    }
    
    public void setActionType(String actionType) {
        this.actionType = actionType;
    }
    
    public String getTargetId() {
        return targetId;
    }
    
    public void setTargetId(String targetId) {
        this.targetId = targetId;
    }
    
    public String getReason() {
        return reason;
    }
    
    public void setReason(String reason) {
        this.reason = reason;
    }
    
    public LocalDateTime getActionTimestamp() {
        return actionTimestamp;
    }
    
    public void setActionTimestamp(LocalDateTime actionTimestamp) {
        this.actionTimestamp = actionTimestamp;
    }
}
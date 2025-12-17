package com.pbl6.backend.response;

import java.util.Map;

public class MetricsOverviewResponse {
    
    private long totalUsers;
    private long activeUsers;
    private long suspendedUsers;
    private long bannedUsers;
    private long totalPosts;
    private long pendingReports;
    private AIPerformanceMetrics aiPerformance;
    
    // Nested class for AI performance
    public static class AIPerformanceMetrics {
        private long total;
        private long success;
        private long failed;
        private double successRate;
        
        public AIPerformanceMetrics() {}
        
        public AIPerformanceMetrics(long total, long success, long failed) {
            this.total = total;
            this.success = success;
            this.failed = failed;
            this.successRate = total > 0 ? (success * 100.0 / total) : 0;
        }
        
        // Getters and Setters
        public long getTotal() { return total; }
        public void setTotal(long total) { this.total = total; }
        public long getSuccess() { return success; }
        public void setSuccess(long success) { this.success = success; }
        public long getFailed() { return failed; }
        public void setFailed(long failed) { this.failed = failed; }
        public double getSuccessRate() { return successRate; }
        public void setSuccessRate(double successRate) { this.successRate = successRate; }
    }
    
    // Constructors
    public MetricsOverviewResponse() {}
    
    // Getters and Setters
    public long getTotalUsers() {
        return totalUsers;
    }
    
    public void setTotalUsers(long totalUsers) {
        this.totalUsers = totalUsers;
    }
    
    public long getActiveUsers() {
        return activeUsers;
    }
    
    public void setActiveUsers(long activeUsers) {
        this.activeUsers = activeUsers;
    }
    
    public long getSuspendedUsers() {
        return suspendedUsers;
    }
    
    public void setSuspendedUsers(long suspendedUsers) {
        this.suspendedUsers = suspendedUsers;
    }
    
    public long getBannedUsers() {
        return bannedUsers;
    }
    
    public void setBannedUsers(long bannedUsers) {
        this.bannedUsers = bannedUsers;
    }
    
    public long getTotalPosts() {
        return totalPosts;
    }
    
    public void setTotalPosts(long totalPosts) {
        this.totalPosts = totalPosts;
    }
    
    public long getPendingReports() {
        return pendingReports;
    }
    
    public void setPendingReports(long pendingReports) {
        this.pendingReports = pendingReports;
    }
    
    public AIPerformanceMetrics getAiPerformance() {
        return aiPerformance;
    }
    
    public void setAiPerformance(AIPerformanceMetrics aiPerformance) {
        this.aiPerformance = aiPerformance;
    }
}

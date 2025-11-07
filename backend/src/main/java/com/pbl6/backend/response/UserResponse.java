package com.pbl6.backend.response;

import java.time.LocalDateTime;

public class UserResponse {
    
    private String userId;
    private String username;
    private String fullName;
    private String phoneNumber;
    private String bio;
    private String profilePictureUrl;
    private String accountStatus;
    private String subscriptionPlan;
    private LocalDateTime createdAt;
    
    // Constructors
    public UserResponse() {}
    
    public UserResponse(String userId, String username, String fullName, String phoneNumber, 
                       String bio, String profilePictureUrl, String accountStatus, 
                       String subscriptionPlan, LocalDateTime createdAt) {
        this.userId = userId;
        this.username = username;
        this.fullName = fullName;
        this.phoneNumber = phoneNumber;
        this.bio = bio;
        this.profilePictureUrl = profilePictureUrl;
        this.accountStatus = accountStatus;
        this.subscriptionPlan = subscriptionPlan;
        this.createdAt = createdAt;
    }
    
    // Getters and Setters
    public String getUserId() {
        return userId;
    }
    
    public void setUserId(String userId) {
        this.userId = userId;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    
    public String getPhoneNumber() {
        return phoneNumber;
    }
    
    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }
    
    public String getBio() {
        return bio;
    }
    
    public void setBio(String bio) {
        this.bio = bio;
    }
    
    public String getProfilePictureUrl() {
        return profilePictureUrl;
    }
    
    public void setProfilePictureUrl(String profilePictureUrl) {
        this.profilePictureUrl = profilePictureUrl;
    }
    
    public String getAccountStatus() {
        return accountStatus;
    }
    
    public void setAccountStatus(String accountStatus) {
        this.accountStatus = accountStatus;
    }
    
    public String getSubscriptionPlan() {
        return subscriptionPlan;
    }
    
    public void setSubscriptionPlan(String subscriptionPlan) {
        this.subscriptionPlan = subscriptionPlan;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
package com.pbl6.backend.response;

import java.time.LocalDateTime;

public class PostReactionResponse {
    
    private String reactionId;
    private UserResponse user;
    private String emojiType;
    private LocalDateTime createdAt;
    
    // Constructors
    public PostReactionResponse() {}
    
    public PostReactionResponse(String reactionId, UserResponse user, String emojiType, LocalDateTime createdAt) {
        this.reactionId = reactionId;
        this.user = user;
        this.emojiType = emojiType;
        this.createdAt = createdAt;
    }
    
    // Getters and Setters
    public String getReactionId() {
        return reactionId;
    }
    
    public void setReactionId(String reactionId) {
        this.reactionId = reactionId;
    }
    
    public UserResponse getUser() {
        return user;
    }
    
    public void setUser(UserResponse user) {
        this.user = user;
    }
    
    public String getEmojiType() {
        return emojiType;
    }
    
    public void setEmojiType(String emojiType) {
        this.emojiType = emojiType;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
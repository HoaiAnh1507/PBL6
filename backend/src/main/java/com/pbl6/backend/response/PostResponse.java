package com.pbl6.backend.response;

import java.time.LocalDateTime;
import java.util.List;

public class PostResponse {
    
    private String postId;
    private UserResponse user;
    private String caption;
    private String mediaType;
    private String mediaUrl;
    private String captionStatus;
    private LocalDateTime createdAt;
    private List<UserResponse> recipients;
    private List<PostReactionResponse> reactions;
    private long totalReactions;
    
    // Constructors
    public PostResponse() {}
    
    public PostResponse(String postId, UserResponse user, String caption, String mediaType, 
                       String mediaUrl, String captionStatus, LocalDateTime createdAt,
                       List<UserResponse> recipients, List<PostReactionResponse> reactions, long totalReactions) {
        this.postId = postId;
        this.user = user;
        this.caption = caption;
        this.mediaType = mediaType;
        this.mediaUrl = mediaUrl;
        this.captionStatus = captionStatus;
        this.createdAt = createdAt;
        this.recipients = recipients;
        this.reactions = reactions;
        this.totalReactions = totalReactions;
    }
    
    // Getters and Setters
    public String getPostId() {
        return postId;
    }
    
    public void setPostId(String postId) {
        this.postId = postId;
    }
    
    public UserResponse getUser() {
        return user;
    }
    
    public void setUser(UserResponse user) {
        this.user = user;
    }
    
    public String getCaption() {
        return caption;
    }
    
    public void setCaption(String caption) {
        this.caption = caption;
    }
    
    public String getMediaType() {
        return mediaType;
    }
    
    public void setMediaType(String mediaType) {
        this.mediaType = mediaType;
    }
    
    public String getMediaUrl() {
        return mediaUrl;
    }
    
    public void setMediaUrl(String mediaUrl) {
        this.mediaUrl = mediaUrl;
    }
    
    public String getCaptionStatus() {
        return captionStatus;
    }
    
    public void setCaptionStatus(String captionStatus) {
        this.captionStatus = captionStatus;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public List<UserResponse> getRecipients() {
        return recipients;
    }
    
    public void setRecipients(List<UserResponse> recipients) {
        this.recipients = recipients;
    }
    
    public List<PostReactionResponse> getReactions() {
        return reactions;
    }
    
    public void setReactions(List<PostReactionResponse> reactions) {
        this.reactions = reactions;
    }
    
    public long getTotalReactions() {
        return totalReactions;
    }
    
    public void setTotalReactions(long totalReactions) {
        this.totalReactions = totalReactions;
    }
}
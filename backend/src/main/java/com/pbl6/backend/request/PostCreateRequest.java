package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

import java.util.List;

public class PostCreateRequest {
    
    @Size(max = 2000, message = "Caption must not exceed 2000 characters")
    private String caption;
    
    @NotBlank(message = "Media type is required")
    private String mediaType;
    
    @NotBlank(message = "Media URL is required")
    private String mediaUrl;
    
    private String captionStatus = "VISIBLE";
    
    private List<String> recipientIds;
    
    // Constructors
    public PostCreateRequest() {}
    
    public PostCreateRequest(String caption, String mediaType, String mediaUrl, String captionStatus, List<String> recipientIds) {
        this.caption = caption;
        this.mediaType = mediaType;
        this.mediaUrl = mediaUrl;
        this.captionStatus = captionStatus;
        this.recipientIds = recipientIds;
    }
    
    // Getters and Setters
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
    
    public List<String> getRecipientIds() {
        return recipientIds;
    }
    
    public void setRecipientIds(List<String> recipientIds) {
        this.recipientIds = recipientIds;
    }
}
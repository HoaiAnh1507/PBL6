package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

public class AiCaptionInitRequest {
    @NotBlank(message = "mediaType là bắt buộc")
    private String mediaType; // PHOTO | VIDEO

    @NotBlank(message = "mediaUrl là bắt buộc")
    private String mediaUrl;

    private String mood; // User selected mood: happy, sad, excited, etc.

    public AiCaptionInitRequest() {
    }

    public AiCaptionInitRequest(String mediaType, String mediaUrl) {
        this.mediaType = mediaType;
        this.mediaUrl = mediaUrl;
    }

    public AiCaptionInitRequest(String mediaType, String mediaUrl, String mood) {
        this.mediaType = mediaType;
        this.mediaUrl = mediaUrl;
        this.mood = mood;
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

    public String getMood() {
        return mood;
    }

    public void setMood(String mood) {
        this.mood = mood;
    }
}
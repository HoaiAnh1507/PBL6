package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class PostDirectCreateRequest {
    @NotBlank(message = "mediaType là bắt buộc")
    private String mediaType;

    @NotBlank(message = "mediaUrl là bắt buộc")
    private String mediaUrl;

    @Size(max = 2000, message = "Caption không vượt quá 2000 ký tự")
    private String finalCaption; // có thể null hoặc rỗng

    public PostDirectCreateRequest() {}

    public PostDirectCreateRequest(String mediaType, String mediaUrl, String finalCaption) {
        this.mediaType = mediaType;
        this.mediaUrl = mediaUrl;
        this.finalCaption = finalCaption;
    }

    public String getMediaType() { return mediaType; }
    public void setMediaType(String mediaType) { this.mediaType = mediaType; }

    public String getMediaUrl() { return mediaUrl; }
    public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }

    public String getFinalCaption() { return finalCaption; }
    public void setFinalCaption(String finalCaption) { this.finalCaption = finalCaption; }
}
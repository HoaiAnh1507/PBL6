package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

public class PostDirectCreateRequest {
    @NotBlank(message = "mediaType là bắt buộc")
    private String mediaType;

    @NotBlank(message = "mediaUrl là bắt buộc")
    private String mediaUrl;

    @Size(max = 2000, message = "Caption không vượt quá 2000 ký tự")
    private String finalCaption; // có thể null hoặc rỗng

    // Danh sách userId của người nhận bài đăng
    private List<String> recipientIds;

    public PostDirectCreateRequest() {}

    public PostDirectCreateRequest(String mediaType, String mediaUrl, String finalCaption, List<String> recipientIds) {
        this.mediaType = mediaType;
        this.mediaUrl = mediaUrl;
        this.finalCaption = finalCaption;
        this.recipientIds = recipientIds;
    }

    public String getMediaType() { return mediaType; }
    public void setMediaType(String mediaType) { this.mediaType = mediaType; }

    public String getMediaUrl() { return mediaUrl; }
    public void setMediaUrl(String mediaUrl) { this.mediaUrl = mediaUrl; }

    public String getFinalCaption() { return finalCaption; }
    public void setFinalCaption(String finalCaption) { this.finalCaption = finalCaption; }

    public List<String> getRecipientIds() { return recipientIds; }
    public void setRecipientIds(List<String> recipientIds) { this.recipientIds = recipientIds; }
}
package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

public class PostReactionRequest {
    @NotBlank
    private String emojiType;

    public PostReactionRequest() {}

    public PostReactionRequest(String emojiType) {
        this.emojiType = emojiType;
    }

    public String getEmojiType() {
        return emojiType;
    }

    public void setEmojiType(String emojiType) {
        this.emojiType = emojiType;
    }
}
package com.pbl6.backend.response;

public class AiCaptionInitResponse {
    private String postId;
    private String generatedCaption;

    public AiCaptionInitResponse() {}

    public AiCaptionInitResponse(String postId, String generatedCaption) {
        this.postId = postId;
        this.generatedCaption = generatedCaption;
    }

    public String getPostId() {
        return postId;
    }

    public void setPostId(String postId) {
        this.postId = postId;
    }

    public String getGeneratedCaption() {
        return generatedCaption;
    }

    public void setGeneratedCaption(String generatedCaption) {
        this.generatedCaption = generatedCaption;
    }
}
package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class PostFinalizeRequest {
    @NotBlank(message = "postId là bắt buộc")
    private String postId;

    @NotBlank(message = "finalCaption là bắt buộc")
    @Size(max = 2000, message = "Caption không vượt quá 2000 ký tự")
    private String finalCaption;

    public PostFinalizeRequest() {}

    public PostFinalizeRequest(String postId, String finalCaption) {
        this.postId = postId;
        this.finalCaption = finalCaption;
    }

    public String getPostId() {
        return postId;
    }

    public void setPostId(String postId) {
        this.postId = postId;
    }

    public String getFinalCaption() {
        return finalCaption;
    }

    public void setFinalCaption(String finalCaption) {
        this.finalCaption = finalCaption;
    }
}
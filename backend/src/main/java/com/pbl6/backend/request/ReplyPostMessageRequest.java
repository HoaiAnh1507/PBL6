package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class ReplyPostMessageRequest {
    @NotBlank(message = "postId là bắt buộc")
    private String postId;

    @Size(max = 4000, message = "Nội dung tin nhắn không vượt quá 4000 ký tự")
    private String content; // có thể để trống nếu chỉ muốn gửi media của post

    public ReplyPostMessageRequest() {}

    public ReplyPostMessageRequest(String postId, String content) {
        this.postId = postId;
        this.content = content;
    }

    public String getPostId() { return postId; }
    public void setPostId(String postId) { this.postId = postId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
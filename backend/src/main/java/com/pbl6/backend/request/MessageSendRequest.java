package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class MessageSendRequest {
    @NotBlank(message = "conversationId là bắt buộc")
    private String conversationId;

    @NotBlank(message = "content là bắt buộc")
    @Size(max = 4000, message = "Nội dung tin nhắn không vượt quá 4000 ký tự")
    private String content;

    public MessageSendRequest() {}

    public MessageSendRequest(String conversationId, String content) {
        this.conversationId = conversationId;
        this.content = content;
    }

    public String getConversationId() { return conversationId; }
    public void setConversationId(String conversationId) { this.conversationId = conversationId; }

    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
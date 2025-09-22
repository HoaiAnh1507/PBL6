package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class MessageSendRequest {
    
    @NotBlank(message = "Conversation ID is required")
    private String conversationId;
    
    @NotBlank(message = "Content is required")
    @Size(max = 1000, message = "Message content must not exceed 1000 characters")
    private String content;
    
    private String repliedToPostId;
    
    // Constructors
    public MessageSendRequest() {}
    
    public MessageSendRequest(String conversationId, String content, String repliedToPostId) {
        this.conversationId = conversationId;
        this.content = content;
        this.repliedToPostId = repliedToPostId;
    }
    
    // Getters and Setters
    public String getConversationId() {
        return conversationId;
    }
    
    public void setConversationId(String conversationId) {
        this.conversationId = conversationId;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public String getRepliedToPostId() {
        return repliedToPostId;
    }
    
    public void setRepliedToPostId(String repliedToPostId) {
        this.repliedToPostId = repliedToPostId;
    }
}
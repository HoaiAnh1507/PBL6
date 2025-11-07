package com.pbl6.backend.response;

import java.time.LocalDateTime;

public class MessageResponse {
    
    private String messageId;
    private String conversationId;
    private UserResponse sender;
    private String content;
    private PostResponse repliedToPost;
    private LocalDateTime sentAt;
    
    // Constructors
    public MessageResponse() {}
    
    public MessageResponse(String messageId, String conversationId, UserResponse sender, 
                          String content, PostResponse repliedToPost, LocalDateTime sentAt) {
        this.messageId = messageId;
        this.conversationId = conversationId;
        this.sender = sender;
        this.content = content;
        this.repliedToPost = repliedToPost;
        this.sentAt = sentAt;
    }
    
    // Getters and Setters
    public String getMessageId() {
        return messageId;
    }
    
    public void setMessageId(String messageId) {
        this.messageId = messageId;
    }
    
    public String getConversationId() {
        return conversationId;
    }
    
    public void setConversationId(String conversationId) {
        this.conversationId = conversationId;
    }
    
    public UserResponse getSender() {
        return sender;
    }
    
    public void setSender(UserResponse sender) {
        this.sender = sender;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    public PostResponse getRepliedToPost() {
        return repliedToPost;
    }
    
    public void setRepliedToPost(PostResponse repliedToPost) {
        this.repliedToPost = repliedToPost;
    }
    
    public LocalDateTime getSentAt() {
        return sentAt;
    }
    
    public void setSentAt(LocalDateTime sentAt) {
        this.sentAt = sentAt;
    }
}
package com.pbl6.backend.response;

import java.time.LocalDateTime;
import java.util.List;

public class ConversationResponse {
    private String conversationId;
    private PublicUserResponse userOne;
    private PublicUserResponse userTwo;
    private LocalDateTime lastMessageAt;
    private LocalDateTime createdAt;
    private List<MessageResponse> messages;

    public ConversationResponse() {}

    public ConversationResponse(String conversationId,
                                PublicUserResponse userOne,
                                PublicUserResponse userTwo,
                                LocalDateTime lastMessageAt,
                                LocalDateTime createdAt,
                                List<MessageResponse> messages) {
        this.conversationId = conversationId;
        this.userOne = userOne;
        this.userTwo = userTwo;
        this.lastMessageAt = lastMessageAt;
        this.createdAt = createdAt;
        this.messages = messages;
    }

    public String getConversationId() { return conversationId; }
    public void setConversationId(String conversationId) { this.conversationId = conversationId; }

    public PublicUserResponse getUserOne() { return userOne; }
    public void setUserOne(PublicUserResponse userOne) { this.userOne = userOne; }

    public PublicUserResponse getUserTwo() { return userTwo; }
    public void setUserTwo(PublicUserResponse userTwo) { this.userTwo = userTwo; }

    public LocalDateTime getLastMessageAt() { return lastMessageAt; }
    public void setLastMessageAt(LocalDateTime lastMessageAt) { this.lastMessageAt = lastMessageAt; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public List<MessageResponse> getMessages() { return messages; }
    public void setMessages(List<MessageResponse> messages) { this.messages = messages; }
}
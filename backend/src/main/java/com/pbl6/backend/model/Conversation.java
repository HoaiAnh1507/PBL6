package com.pbl6.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.GenericGenerator;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "Conversations", indexes = {
    @Index(name = "idx_conversation_user_one_id", columnList = "user_one_id"),
    @Index(name = "idx_conversation_user_two_id", columnList = "user_two_id"),
    @Index(name = "idx_conversation_last_message_at", columnList = "last_message_at"),
    @Index(name = "idx_conversation_users", columnList = "user_one_id, user_two_id"),
    @Index(name = "idx_conversation_created_at", columnList = "created_at")
})
public class Conversation {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "conversation_id", length = 36)
    private String conversationId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_one_id", nullable = false)
    private User userOne;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_two_id", nullable = false)
    private User userTwo;
    
    @Column(name = "last_message_at")
    private LocalDateTime lastMessageAt;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    // Relationships
    @OneToMany(mappedBy = "conversation", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Message> messages;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Constructors
    public Conversation() {}
    
    public Conversation(User userOne, User userTwo) {
        this.userOne = userOne;
        this.userTwo = userTwo;
    }
    
    // Getters and Setters
    public String getConversationId() {
        return conversationId;
    }
    
    public void setConversationId(String conversationId) {
        this.conversationId = conversationId;
    }
    
    public User getUserOne() {
        return userOne;
    }
    
    public void setUserOne(User userOne) {
        this.userOne = userOne;
    }
    
    public User getUserTwo() {
        return userTwo;
    }
    
    public void setUserTwo(User userTwo) {
        this.userTwo = userTwo;
    }
    
    public LocalDateTime getLastMessageAt() {
        return lastMessageAt;
    }
    
    public void setLastMessageAt(LocalDateTime lastMessageAt) {
        this.lastMessageAt = lastMessageAt;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public List<Message> getMessages() {
        return messages;
    }
    
    public void setMessages(List<Message> messages) {
        this.messages = messages;
    }
}
package com.pbl6.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.GenericGenerator;
import java.time.LocalDateTime;

@Entity
@Table(name = "Post_Reactions", indexes = {
    @Index(name = "idx_post_reaction_post_id", columnList = "post_id"),
    @Index(name = "idx_post_reaction_user_id", columnList = "user_id"),
    @Index(name = "idx_post_reaction_emoji_type", columnList = "emoji_type"),
    @Index(name = "idx_post_reaction_post_user", columnList = "post_id, user_id"),
    @Index(name = "idx_post_reaction_created_at", columnList = "created_at")
})
public class PostReaction {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "reaction_id", length = 36)
    private String reactionId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private Post post;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(name = "emoji_type", length = 10, nullable = false)
    private String emojiType;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Constructors
    public PostReaction() {}
    
    public PostReaction(Post post, User user, String emojiType) {
        this.post = post;
        this.user = user;
        this.emojiType = emojiType;
    }
    
    // Getters and Setters
    public String getReactionId() {
        return reactionId;
    }
    
    public void setReactionId(String reactionId) {
        this.reactionId = reactionId;
    }
    
    public Post getPost() {
        return post;
    }
    
    public void setPost(Post post) {
        this.post = post;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
    }
    
    public String getEmojiType() {
        return emojiType;
    }
    
    public void setEmojiType(String emojiType) {
        this.emojiType = emojiType;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
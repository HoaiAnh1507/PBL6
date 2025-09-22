package com.pbl6.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.GenericGenerator;

@Entity
@Table(name = "Post_Recipients", indexes = {
    @Index(name = "idx_post_recipient_post_id", columnList = "post_id"),
    @Index(name = "idx_post_recipient_recipient_id", columnList = "recipient_id"),
    @Index(name = "idx_post_recipient_post_recipient", columnList = "post_id, recipient_id")
})
public class PostRecipient {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "post_recipient_id", length = 36)
    private String postRecipientId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "post_id", nullable = false)
    private Post post;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "recipient_id", nullable = false)
    private User recipient;
    
    // Constructors
    public PostRecipient() {}
    
    public PostRecipient(Post post, User recipient) {
        this.post = post;
        this.recipient = recipient;
    }
    
    // Getters and Setters
    public String getPostRecipientId() {
        return postRecipientId;
    }
    
    public void setPostRecipientId(String postRecipientId) {
        this.postRecipientId = postRecipientId;
    }
    
    public Post getPost() {
        return post;
    }
    
    public void setPost(Post post) {
        this.post = post;
    }
    
    public User getRecipient() {
        return recipient;
    }
    
    public void setRecipient(User recipient) {
        this.recipient = recipient;
    }
}
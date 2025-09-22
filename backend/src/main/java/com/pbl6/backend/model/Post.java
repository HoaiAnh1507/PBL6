package com.pbl6.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.GenericGenerator;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "Posts", indexes = {
    @Index(name = "idx_post_user_id", columnList = "user_id"),
    @Index(name = "idx_post_created_at", columnList = "created_at"),
    @Index(name = "idx_post_caption_status", columnList = "caption_status"),
    @Index(name = "idx_post_media_type", columnList = "media_type"),
    @Index(name = "idx_post_user_created", columnList = "user_id, created_at")
})
public class Post {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "post_id", length = 36)
    private String postId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "media_type", nullable = false)
    private MediaType mediaType;
    
    @Column(name = "media_url", columnDefinition = "TEXT", nullable = false)
    private String mediaUrl;
    
    @Column(name = "generated_caption", columnDefinition = "TEXT")
    private String generatedCaption;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "caption_status", nullable = false)
    private CaptionStatus captionStatus = CaptionStatus.PENDING;
    
    @Column(name = "user_edited_caption", columnDefinition = "TEXT")
    private String userEditedCaption;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    // Relationships
    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<PostRecipient> recipients;
    
    @OneToMany(mappedBy = "post", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<PostReaction> reactions;
    
    @OneToMany(mappedBy = "repliedToPost", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Message> repliedMessages;
    
    @OneToMany(mappedBy = "reportedPost", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<ModerationReport> reports;
    
    public enum MediaType {
        PHOTO, VIDEO
    }
    
    public enum CaptionStatus {
        PENDING, COMPLETED, FAILED
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Constructors
    public Post() {}
    
    public Post(User user, MediaType mediaType, String mediaUrl) {
        this.user = user;
        this.mediaType = mediaType;
        this.mediaUrl = mediaUrl;
    }
    
    // Getters and Setters
    public String getPostId() {
        return postId;
    }
    
    public void setPostId(String postId) {
        this.postId = postId;
    }
    
    public User getUser() {
        return user;
    }
    
    public void setUser(User user) {
        this.user = user;
    }
    
    public MediaType getMediaType() {
        return mediaType;
    }
    
    public void setMediaType(MediaType mediaType) {
        this.mediaType = mediaType;
    }
    
    public String getMediaUrl() {
        return mediaUrl;
    }
    
    public void setMediaUrl(String mediaUrl) {
        this.mediaUrl = mediaUrl;
    }
    
    public String getGeneratedCaption() {
        return generatedCaption;
    }
    
    public void setGeneratedCaption(String generatedCaption) {
        this.generatedCaption = generatedCaption;
    }
    
    public CaptionStatus getCaptionStatus() {
        return captionStatus;
    }
    
    public void setCaptionStatus(CaptionStatus captionStatus) {
        this.captionStatus = captionStatus;
    }
    
    public String getUserEditedCaption() {
        return userEditedCaption;
    }
    
    public void setUserEditedCaption(String userEditedCaption) {
        this.userEditedCaption = userEditedCaption;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public List<PostRecipient> getRecipients() {
        return recipients;
    }
    
    public void setRecipients(List<PostRecipient> recipients) {
        this.recipients = recipients;
    }
    
    public List<PostReaction> getReactions() {
        return reactions;
    }
    
    public void setReactions(List<PostReaction> reactions) {
        this.reactions = reactions;
    }
    
    public List<Message> getRepliedMessages() {
        return repliedMessages;
    }
    
    public void setRepliedMessages(List<Message> repliedMessages) {
        this.repliedMessages = repliedMessages;
    }
    
    public List<ModerationReport> getReports() {
        return reports;
    }
    
    public void setReports(List<ModerationReport> reports) {
        this.reports = reports;
    }
}
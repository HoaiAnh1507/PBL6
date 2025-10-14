package com.pbl6.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.GenericGenerator;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "Users", indexes = {
    @Index(name = "idx_user_username", columnList = "username"),
    @Index(name = "idx_user_phone_number", columnList = "phone_number"),
    @Index(name = "idx_user_email", columnList = "email"),
    @Index(name = "idx_user_account_status", columnList = "account_status"),
    @Index(name = "idx_user_subscription_status", columnList = "subscription_status"),
    @Index(name = "idx_user_created_at", columnList = "created_at")
})
public class User {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "user_id", length = 36)
    private String userId;
    
    @Column(name = "phone_number", length = 20, nullable = false, unique = true)
    private String phoneNumber;
    
    @Column(name = "username", length = 30, nullable = false, unique = true)
    private String username;
    
    @Column(name = "email", length = 100, nullable = false, unique = true)
    private String email;
    
    @Column(name = "full_name", length = 100, nullable = false)
    private String fullName;
    
    @Column(name = "profile_picture_url", columnDefinition = "TEXT")
    private String profilePictureUrl;
    
    @Column(name = "password_hash", columnDefinition = "TEXT", nullable = false)
    private String passwordHash;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "subscription_status", nullable = false)
    private SubscriptionStatus subscriptionStatus = SubscriptionStatus.FREE;
    
    @Column(name = "subscription_expires_at")
    private LocalDateTime subscriptionExpiresAt;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "account_status", nullable = false)
    private AccountStatus accountStatus = AccountStatus.ACTIVE;
    
    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;
    
    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;
    
    // Relationships
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Post> posts;
    
    @OneToMany(mappedBy = "userOne", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Friendship> friendshipsAsUserOne;
    
    @OneToMany(mappedBy = "userTwo", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Friendship> friendshipsAsUserTwo;
    
    public enum SubscriptionStatus {
        FREE, GOLD
    }
    
    public enum AccountStatus {
        ACTIVE, SUSPENDED, BANNED
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }
    
    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
    
    // Constructors
    public User() {}
    
    public User(String phoneNumber, String username, String email, String fullName, String passwordHash) {
        this.phoneNumber = phoneNumber;
        this.username = username;
        this.email = email;
        this.fullName = fullName;
        this.passwordHash = passwordHash;
    }
    
    // Getters and Setters
    public String getUserId() {
        return userId;
    }
    
    public void setUserId(String userId) {
        this.userId = userId;
    }
    
    public String getPhoneNumber() {
        return phoneNumber;
    }
    
    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
    }
    
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getEmail() {
        return email;
    }
    
    public void setEmail(String email) {
        this.email = email;
    }
    
    public String getFullName() {
        return fullName;
    }
    
    public void setFullName(String fullName) {
        this.fullName = fullName;
    }
    
    public String getProfilePictureUrl() {
        return profilePictureUrl;
    }
    
    public void setProfilePictureUrl(String profilePictureUrl) {
        this.profilePictureUrl = profilePictureUrl;
    }
    
    public String getPasswordHash() {
        return passwordHash;
    }
    
    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }
    
    public SubscriptionStatus getSubscriptionStatus() {
        return subscriptionStatus;
    }
    
    public void setSubscriptionStatus(SubscriptionStatus subscriptionStatus) {
        this.subscriptionStatus = subscriptionStatus;
    }
    
    public LocalDateTime getSubscriptionExpiresAt() {
        return subscriptionExpiresAt;
    }
    
    public void setSubscriptionExpiresAt(LocalDateTime subscriptionExpiresAt) {
        this.subscriptionExpiresAt = subscriptionExpiresAt;
    }
    
    public AccountStatus getAccountStatus() {
        return accountStatus;
    }
    
    public void setAccountStatus(AccountStatus accountStatus) {
        this.accountStatus = accountStatus;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
    
    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }
    
    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
    
    public List<Post> getPosts() {
        return posts;
    }
    
    public void setPosts(List<Post> posts) {
        this.posts = posts;
    }
    
    public List<Friendship> getFriendshipsAsUserOne() {
        return friendshipsAsUserOne;
    }
    
    public void setFriendshipsAsUserOne(List<Friendship> friendshipsAsUserOne) {
        this.friendshipsAsUserOne = friendshipsAsUserOne;
    }
    
    public List<Friendship> getFriendshipsAsUserTwo() {
        return friendshipsAsUserTwo;
    }
    
    public void setFriendshipsAsUserTwo(List<Friendship> friendshipsAsUserTwo) {
        this.friendshipsAsUserTwo = friendshipsAsUserTwo;
    }
}
package com.pbl6.backend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.GenericGenerator;
import java.time.LocalDateTime;

@Entity
@Table(name = "Friendships")
public class Friendship {
    
    @Id
    @GeneratedValue(generator = "UUID")
    @GenericGenerator(name = "UUID", strategy = "org.hibernate.id.UUIDGenerator")
    @Column(name = "friendship_id", length = 36)
    private String friendshipId;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_one_id", nullable = false)
    private User userOne;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_two_id", nullable = false)
    private User userTwo;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private FriendshipStatus status = FriendshipStatus.PENDING;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "action_user_id")
    private User actionUser;
    
    public enum FriendshipStatus {
        PENDING, ACCEPTED, BLOCKED
    }
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
    
    // Constructors
    public Friendship() {}
    
    public Friendship(User userOne, User userTwo) {
        this.userOne = userOne;
        this.userTwo = userTwo;
    }
    
    public Friendship(User userOne, User userTwo, FriendshipStatus status) {
        this.userOne = userOne;
        this.userTwo = userTwo;
        this.status = status;
    }
    
    // Getters and Setters
    public String getFriendshipId() {
        return friendshipId;
    }
    
    public void setFriendshipId(String friendshipId) {
        this.friendshipId = friendshipId;
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
    
    public FriendshipStatus getStatus() {
        return status;
    }
    
    public void setStatus(FriendshipStatus status) {
        this.status = status;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public User getActionUser() {
        return actionUser;
    }

    public void setActionUser(User actionUser) {
        this.actionUser = actionUser;
    }
}
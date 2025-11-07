package com.pbl6.backend.response;

import com.pbl6.backend.model.Friendship;
import java.time.LocalDateTime;

public class FriendshipResponse {
    
    private String friendshipId;
    private String userOneId;
    private String userTwoId;
    private String userOneName;
    private String userTwoName;
    private String userOneUsername;
    private String userTwoUsername;
    private String status;
    private LocalDateTime createdAt;

    // Constructors
    public FriendshipResponse() {}

    public FriendshipResponse(Friendship friendship) {
        this.friendshipId = friendship.getFriendshipId();
        this.userOneId = friendship.getUserOne().getUserId();
        this.userTwoId = friendship.getUserTwo().getUserId();
        this.userOneName = friendship.getUserOne().getFullName();
        this.userTwoName = friendship.getUserTwo().getFullName();
        this.userOneUsername = friendship.getUserOne().getUsername();
        this.userTwoUsername = friendship.getUserTwo().getUsername();
        this.status = friendship.getStatus().toString();
        this.createdAt = friendship.getCreatedAt();
    }

    // Getters and Setters
    public String getFriendshipId() {
        return friendshipId;
    }

    public void setFriendshipId(String friendshipId) {
        this.friendshipId = friendshipId;
    }

    public String getUserOneId() {
        return userOneId;
    }

    public void setUserOneId(String userOneId) {
        this.userOneId = userOneId;
    }

    public String getUserTwoId() {
        return userTwoId;
    }

    public void setUserTwoId(String userTwoId) {
        this.userTwoId = userTwoId;
    }

    public String getUserOneName() {
        return userOneName;
    }

    public void setUserOneName(String userOneName) {
        this.userOneName = userOneName;
    }

    public String getUserTwoName() {
        return userTwoName;
    }

    public void setUserTwoName(String userTwoName) {
        this.userTwoName = userTwoName;
    }

    public String getUserOneUsername() {
        return userOneUsername;
    }

    public void setUserOneUsername(String userOneUsername) {
        this.userOneUsername = userOneUsername;
    }

    public String getUserTwoUsername() {
        return userTwoUsername;
    }

    public void setUserTwoUsername(String userTwoUsername) {
        this.userTwoUsername = userTwoUsername;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
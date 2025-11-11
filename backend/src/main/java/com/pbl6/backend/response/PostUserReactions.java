package com.pbl6.backend.response;

import java.util.List;

public class PostUserReactions {
    private String userId;
    private String username;
    private String fullName;
    private String profilePictureUrl;
    private List<String> reactions;

    public PostUserReactions() {}

    public PostUserReactions(String userId, String username, String fullName, String profilePictureUrl, List<String> reactions) {
        this.userId = userId;
        this.username = username;
        this.fullName = fullName;
        this.profilePictureUrl = profilePictureUrl;
        this.reactions = reactions;
    }

    public String getUserId() {
        return userId;
    }

    public void setUserId(String userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
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

    public List<String> getReactions() {
        return reactions;
    }

    public void setReactions(List<String> reactions) {
        this.reactions = reactions;
    }
}
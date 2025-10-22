package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class CreateFriendshipRequest {
    
    @NotBlank(message = "UUID người dùng không được để trống")
    @Pattern(regexp = "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", 
             message = "UUID người dùng không đúng định dạng")
    private String targetUserId;

    // Constructors
    public CreateFriendshipRequest() {}

    public CreateFriendshipRequest(String targetUserId) {
        this.targetUserId = targetUserId;
    }

    // Getters and Setters
    public String getTargetUserId() {
        return targetUserId;
    }

    public void setTargetUserId(String targetUserId) {
        this.targetUserId = targetUserId;
    }
}
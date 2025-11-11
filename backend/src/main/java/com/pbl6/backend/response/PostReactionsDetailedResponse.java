package com.pbl6.backend.response;

import java.util.List;

public class PostReactionsDetailedResponse {
    private String postId;
    private List<PostUserReactions> users;

    public PostReactionsDetailedResponse() {}

    public PostReactionsDetailedResponse(String postId, List<PostUserReactions> users) {
        this.postId = postId;
        this.users = users;
    }

    public String getPostId() {
        return postId;
    }

    public void setPostId(String postId) {
        this.postId = postId;
    }

    public List<PostUserReactions> getUsers() {
        return users;
    }

    public void setUsers(List<PostUserReactions> users) {
        this.users = users;
    }
}
package com.pbl6.backend.response;

import java.util.List;

public class PostOwnReactionsResponse {
    private String postId;
    private List<String> reaction;

    public PostOwnReactionsResponse() {}

    public PostOwnReactionsResponse(String postId, List<String> reaction) {
        this.postId = postId;
        this.reaction = reaction;
    }

    public String getPostId() {
      return postId;
    }

    public void setPostId(String postId) {
      this.postId = postId;
    }

    public List<String> getReaction() {
      return reaction;
    }

    public void setReaction(List<String> reaction) {
      this.reaction = reaction;
    }
}
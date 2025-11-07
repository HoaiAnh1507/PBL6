package com.pbl6.backend.request;

import jakarta.validation.constraints.NotNull;

/**
 * DTO for receiving caption generation results from AI Server
 */
public class CaptionResultRequest {

    @NotNull(message = "Job ID is required")
    private String jobId;

    @NotNull(message = "Post ID is required")
    private String postId;

    @NotNull(message = "Success flag is required")
    private boolean success;

    private String caption; // Null if failed

    private String errorMessage; // Null if successful

    @NotNull(message = "Secret is required")
    private String secret; // For authentication

    public CaptionResultRequest() {
    }

    public CaptionResultRequest(String jobId, String postId, boolean success, String caption, String errorMessage,
            String secret) {
        this.jobId = jobId;
        this.postId = postId;
        this.success = success;
        this.caption = caption;
        this.errorMessage = errorMessage;
        this.secret = secret;
    }

    public String getJobId() {
        return jobId;
    }

    public void setJobId(String jobId) {
        this.jobId = jobId;
    }

    public String getPostId() {
        return postId;
    }

    public void setPostId(String postId) {
        this.postId = postId;
    }

    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public String getCaption() {
        return caption;
    }

    public void setCaption(String caption) {
        this.caption = caption;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public String getSecret() {
        return secret;
    }

    public void setSecret(String secret) {
        this.secret = secret;
    }
}
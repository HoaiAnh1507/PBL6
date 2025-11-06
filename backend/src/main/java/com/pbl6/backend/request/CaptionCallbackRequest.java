package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

public class CaptionCallbackRequest {
    @NotBlank
    private String jobId;
    @NotBlank
    private String postId;
    @NotBlank
    private String status; // COMPLETED | FAILED

    private String caption; // nullable when FAILED
    private String error;   // nullable when COMPLETED

    public String getJobId() { return jobId; }
    public void setJobId(String jobId) { this.jobId = jobId; }

    public String getPostId() { return postId; }
    public void setPostId(String postId) { this.postId = postId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCaption() { return caption; }
    public void setCaption(String caption) { this.caption = caption; }

    public String getError() { return error; }
    public void setError(String error) { this.error = error; }
}
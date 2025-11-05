package com.pbl6.backend.response;

public class CaptionJobResponse {
    private String jobId;
    private String status; // PENDING | RUNNING | COMPLETED | FAILED
    private String caption; // optional
    private String error;   // optional

    public CaptionJobResponse() {}

    public CaptionJobResponse(String jobId, String status) {
        this.jobId = jobId;
        this.status = status;
    }

    public CaptionJobResponse(String jobId, String status, String caption, String error) {
        this.jobId = jobId;
        this.status = status;
        this.caption = caption;
        this.error = error;
    }

    public String getJobId() { return jobId; }
    public void setJobId(String jobId) { this.jobId = jobId; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getCaption() { return caption; }
    public void setCaption(String caption) { this.caption = caption; }

    public String getError() { return error; }
    public void setError(String error) { this.error = error; }
}
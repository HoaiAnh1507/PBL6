package com.pbl6.backend.request;

public class SasTokenRequest {
    private String containerName;
    private String blobName;
    private Integer expiresInSeconds; // optional, default 300
    // access: "read" (default) or "upload"
    private String access;
    // mediaType: "PHOTO" or "VIDEO" (optional, used when access=upload)
    private String mediaType;

    public String getContainerName() {
        return containerName;
    }

    public void setContainerName(String containerName) {
        this.containerName = containerName;
    }

    public String getBlobName() {
        return blobName;
    }

    public void setBlobName(String blobName) {
        this.blobName = blobName;
    }

    public Integer getExpiresInSeconds() {
        return expiresInSeconds;
    }

    public void setExpiresInSeconds(Integer expiresInSeconds) {
        this.expiresInSeconds = expiresInSeconds;
    }

    public String getAccess() {
        return access;
    }

    public void setAccess(String access) {
        this.access = access;
    }

    public String getMediaType() {
        return mediaType;
    }

    public void setMediaType(String mediaType) {
        this.mediaType = mediaType;
    }
}
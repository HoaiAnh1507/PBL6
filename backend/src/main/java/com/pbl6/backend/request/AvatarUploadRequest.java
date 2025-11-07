package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class AvatarUploadRequest {

    @NotBlank
    @Size(max = 255)
    private String fileName;

    @NotBlank
    @Size(max = 100)
    private String contentType;

    public String getFileName() {
        return fileName;
    }

    public void setFileName(String fileName) {
        this.fileName = fileName;
    }

    public String getContentType() {
        return contentType;
    }

    public void setContentType(String contentType) {
        this.contentType = contentType;
    }
}
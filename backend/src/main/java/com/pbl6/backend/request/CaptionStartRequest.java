package com.pbl6.backend.request;

import jakarta.validation.constraints.Pattern;

public class CaptionStartRequest {
    // Tuỳ chọn: ngôn ngữ kết quả (vi, en, ...)
    @Pattern(regexp = "^[a-zA-Z-_.]*$")
    private String language;

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }
}
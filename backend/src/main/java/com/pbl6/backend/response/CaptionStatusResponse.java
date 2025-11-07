package com.pbl6.backend.response;

/**
 * DTO for mobile polling endpoint to check caption generation status
 */
public class CaptionStatusResponse {

    /**
     * Status of caption generation: PENDING, COMPLETED, FAILED
     */
    private String status;

    /**
     * Flag to indicate if caption is available (avoids race condition)
     */
    private boolean hasCaption;

    /**
     * The generated caption (null if not yet completed or failed)
     */
    private String caption;

    /**
     * Error message if generation failed
     */
    private String errorMessage;

    public CaptionStatusResponse() {
    }

    public CaptionStatusResponse(String status, boolean hasCaption, String caption, String errorMessage) {
        this.status = status;
        this.hasCaption = hasCaption;
        this.caption = caption;
        this.errorMessage = errorMessage;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public boolean isHasCaption() {
        return hasCaption;
    }

    public void setHasCaption(boolean hasCaption) {
        this.hasCaption = hasCaption;
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
}
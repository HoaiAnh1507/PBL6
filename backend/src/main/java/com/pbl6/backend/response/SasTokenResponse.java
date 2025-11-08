package com.pbl6.backend.response;

public class SasTokenResponse {
    private String sasToken;
    private String signedUrl;
    private String expiresOn;

    public SasTokenResponse() {}

    public SasTokenResponse(String sasToken, String signedUrl, String expiresOn) {
        this.sasToken = sasToken;
        this.signedUrl = signedUrl;
        this.expiresOn = expiresOn;
    }

    public String getSasToken() {
        return sasToken;
    }

    public void setSasToken(String sasToken) {
        this.sasToken = sasToken;
    }

    public String getSignedUrl() {
        return signedUrl;
    }

    public void setSignedUrl(String signedUrl) {
        this.signedUrl = signedUrl;
    }

    public String getExpiresOn() {
        return expiresOn;
    }

    public void setExpiresOn(String expiresOn) {
        this.expiresOn = expiresOn;
    }
}
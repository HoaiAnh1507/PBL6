package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

/**
 * Request cho API quên mật khẩu: nhận email hoặc số điện thoại
 */
public class ForgotPasswordRequest {

    @NotBlank(message = "Email hoặc số điện thoại là bắt buộc")
    private String email_or_phonenumber;

    public ForgotPasswordRequest() {}

    public ForgotPasswordRequest(String email_or_phonenumber) {
        this.email_or_phonenumber = email_or_phonenumber;
    }

    public String getEmail_or_phonenumber() {
        return email_or_phonenumber;
    }

    public void setEmail_or_phonenumber(String email_or_phonenumber) {
        this.email_or_phonenumber = email_or_phonenumber;
    }
}
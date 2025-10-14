package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;

/**
 * Request object cho đăng nhập
 * Sử dụng email hoặc số điện thoại để đăng nhập
 */
public class LoginRequest {
    
    @NotBlank(message = "Email hoặc số điện thoại là bắt buộc")
    private String email_or_phonenumber;
    
    @NotBlank(message = "Mật khẩu là bắt buộc")
    private String password;
    
    // Constructors
    public LoginRequest() {}
    
    public LoginRequest(String email_or_phonenumber, String password) {
        this.email_or_phonenumber = email_or_phonenumber;
        this.password = password;
    }
    
    // Getters and Setters
    public String getEmail_or_phonenumber() {
        return email_or_phonenumber;
    }
    
    public void setEmail_or_phonenumber(String email_or_phonenumber) {
        this.email_or_phonenumber = email_or_phonenumber;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
}
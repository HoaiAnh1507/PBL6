package com.pbl6.backend.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/**
 * Request DTO cho API reset password
 * Chứa username và password mới để đặt lại mật khẩu
 */
public class ResetPasswordRequest {
    
    @NotBlank(message = "Username là bắt buộc")
    private String username;
    
    @NotBlank(message = "Mật khẩu mới là bắt buộc")
    @Size(min = 6, message = "Mật khẩu phải có ít nhất 6 ký tự")
    private String password;
    
    // Constructors
    public ResetPasswordRequest() {}
    
    public ResetPasswordRequest(String username, String password) {
        this.username = username;
        this.password = password;
    }
    
    // Getters and Setters
    public String getUsername() {
        return username;
    }
    
    public void setUsername(String username) {
        this.username = username;
    }
    
    public String getPassword() {
        return password;
    }
    
    public void setPassword(String password) {
        this.password = password;
    }
}
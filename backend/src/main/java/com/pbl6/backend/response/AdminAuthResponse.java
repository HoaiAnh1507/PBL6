package com.pbl6.backend.response;

import com.pbl6.backend.model.Admin;

public class AdminAuthResponse {
    
    private String token;
    private AdminResponse admin;
    
    // Constructors
    public AdminAuthResponse() {}
    
    public AdminAuthResponse(String token, Admin admin) {
        this.token = token;
        this.admin = new AdminResponse(admin);
    }
    
    // Getters and Setters
    public String getToken() {
        return token;
    }
    
    public void setToken(String token) {
        this.token = token;
    }
    
    public AdminResponse getAdmin() {
        return admin;
    }
    
    public void setAdmin(AdminResponse admin) {
        this.admin = admin;
    }
}

package com.pbl6.backend.service;

import com.pbl6.backend.model.Admin;
import com.pbl6.backend.repository.AdminRepository;
import com.pbl6.backend.response.AdminAuthResponse;
import com.pbl6.backend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
public class AdminService {

    @Autowired
    private AdminRepository adminRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    public AdminAuthResponse login(String email, String password) {
        Optional<Admin> adminOpt = adminRepository.findByEmail(email);
        
        if (adminOpt.isEmpty()) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        Admin admin = adminOpt.get();
        
        if (!passwordEncoder.matches(password, admin.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        // Generate JWT token for admin
        String token = jwtUtil.generateToken(admin.getAdminId(), "ADMIN");

        return new AdminAuthResponse(token, admin);
    }

    public Optional<Admin> findById(String adminId) {
        return adminRepository.findById(adminId);
    }

    public Optional<Admin> findByEmail(String email) {
        return adminRepository.findByEmail(email);
    }
}

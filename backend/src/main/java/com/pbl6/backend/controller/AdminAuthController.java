package com.pbl6.backend.controller;

import com.pbl6.backend.request.AdminLoginRequest;
import com.pbl6.backend.response.AdminAuthResponse;
import com.pbl6.backend.response.AdminResponse;
import com.pbl6.backend.service.AdminService;
import com.pbl6.backend.model.Admin;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.Optional;

@RestController
@RequestMapping("/api/admin/auth")
@CrossOrigin(origins = "*")
public class AdminAuthController {

    @Autowired
    private AdminService adminService;

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody AdminLoginRequest request) {
        try {
            AdminAuthResponse response = adminService.login(request.getEmail(), request.getPassword());
            return ResponseEntity.ok(response);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/me")
    public ResponseEntity<?> getCurrentAdmin(Authentication authentication) {
        if (authentication == null) {
            return ResponseEntity.status(401).body("Unauthorized");
        }

        String adminId = authentication.getName();
        Optional<Admin> adminOpt = adminService.findById(adminId);

        if (adminOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(new AdminResponse(adminOpt.get()));
    }

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        // JWT is stateless, logout handled on client side
        return ResponseEntity.ok().body("Logged out successfully");
    }
}

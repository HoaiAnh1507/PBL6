package com.pbl6.backend.util;

import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

/**
 * Utility class to generate BCrypt password hashes for admin accounts
 * Run this class to generate hashed passwords for create_admin.sql
 */
public class PasswordHashGenerator {
    
    public static void main(String[] args) {
        BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();
        
        // Generate hash for default admin password
        String password1 = "Admin@123";
        String hash1 = encoder.encode(password1);
        System.out.println("Password: " + password1);
        System.out.println("BCrypt Hash: " + hash1);
        System.out.println();
        
        // Generate hash for moderator password
        String password2 = "Moderator@123";
        String hash2 = encoder.encode(password2);
        System.out.println("Password: " + password2);
        System.out.println("BCrypt Hash: " + hash2);
        System.out.println();
        
        // Verify hashes
        System.out.println("Verification:");
        System.out.println("Hash1 matches: " + encoder.matches(password1, hash1));
        System.out.println("Hash2 matches: " + encoder.matches(password2, hash2));
    }
}

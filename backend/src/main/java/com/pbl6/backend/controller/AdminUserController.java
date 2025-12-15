package com.pbl6.backend.controller;

import com.pbl6.backend.model.User;
import com.pbl6.backend.request.UpdateUserStatusRequest;
import com.pbl6.backend.service.ModerationService;
import com.pbl6.backend.repository.UserRepository;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/users")
@CrossOrigin(origins = "*")
public class AdminUserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ModerationService moderationService;

    @GetMapping
    public ResponseEntity<?> getAllUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String subscription,
            @RequestParam(required = false) String search) {
        
        Pageable pageable = PageRequest.of(page, size);
        Page<User> users;

        // Search by keyword (highest priority)
        if (search != null && !search.isEmpty()) {
            List<User> searchResults = userRepository.searchByKeyword(search);
            int start = (int) pageable.getOffset();
            int end = Math.min((start + pageable.getPageSize()), searchResults.size());
            List<User> pageContent = searchResults.subList(start, end);
            users = new org.springframework.data.domain.PageImpl<>(pageContent, pageable, searchResults.size());
        }
        // Filter by status and/or subscription
        else if ((status != null && !status.isEmpty() && !"ALL".equalsIgnoreCase(status)) ||
                 (subscription != null && !subscription.isEmpty() && !"ALL".equalsIgnoreCase(subscription))) {
            List<User> filteredUsers = userRepository.findAll();
            
            // Filter by status
            if (status != null && !status.isEmpty() && !"ALL".equalsIgnoreCase(status)) {
                try {
                    User.AccountStatus accountStatus = User.AccountStatus.valueOf(status.toUpperCase());
                    filteredUsers = filteredUsers.stream()
                        .filter(u -> u.getAccountStatus() == accountStatus)
                        .collect(java.util.stream.Collectors.toList());
                } catch (IllegalArgumentException e) {
                    // Invalid status, ignore filter
                }
            }
            
            // Filter by subscription
            if (subscription != null && !subscription.isEmpty() && !"ALL".equalsIgnoreCase(subscription)) {
                try {
                    User.SubscriptionStatus subStatus = User.SubscriptionStatus.valueOf(subscription.toUpperCase());
                    filteredUsers = filteredUsers.stream()
                        .filter(u -> u.getSubscriptionStatus() == subStatus)
                        .collect(java.util.stream.Collectors.toList());
                } catch (IllegalArgumentException e) {
                    // Invalid subscription, ignore filter
                }
            }
            
            int start = (int) pageable.getOffset();
            int end = Math.min((start + pageable.getPageSize()), filteredUsers.size());
            List<User> pageContent = filteredUsers.subList(start, end);
            users = new org.springframework.data.domain.PageImpl<>(pageContent, pageable, filteredUsers.size());
        } 
        // Get all users
        else {
            users = userRepository.findAll(pageable);
        }

        return ResponseEntity.ok(users);
    }

    @GetMapping("/{userId}")
    public ResponseEntity<?> getUserById(@PathVariable String userId) {
        return userRepository.findById(userId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PatchMapping("/{userId}/status")
    public ResponseEntity<?> updateUserStatus(
            @PathVariable String userId,
            @Valid @RequestBody UpdateUserStatusRequest request) {
        
        try {
            User updatedUser = moderationService.updateUserStatus(
                    userId, request.getStatus(), request.getReason());
            return ResponseEntity.ok(updatedUser);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }
}

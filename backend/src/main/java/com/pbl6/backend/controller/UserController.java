package com.pbl6.backend.controller;

import com.pbl6.backend.model.User;
import com.pbl6.backend.request.AvatarUploadRequest;
import com.pbl6.backend.request.DeleteAccountRequest;
import com.pbl6.backend.request.UpdateUserProfileRequest;
import com.pbl6.backend.response.AvatarUploadResponse;
import com.pbl6.backend.response.PublicUserResponse;
import com.pbl6.backend.response.UserResponse;
import com.pbl6.backend.security.CustomUserDetailsService;
import com.pbl6.backend.service.UserService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*", maxAge = 3600)
public class UserController {

    @Autowired
    private UserService userService;

    private CustomUserDetailsService.CustomUserPrincipal getCurrentPrincipal() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            return null;
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof CustomUserDetailsService.CustomUserPrincipal userPrincipal) {
            return userPrincipal;
        }
        return null;
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> getUserById(@PathVariable("id") String id) {
        try {
            Optional<User> userOpt = userService.findActiveById(id);
            if (userOpt.isEmpty()) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "Không tìm thấy người dùng");
                return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
            }
            PublicUserResponse res = userService.toPublicUserResponse(userOpt.get());
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi lấy hồ sơ người dùng");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @GetMapping("/profile")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> getOwnProfile() {
        try {
            CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
            if (principal == null) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "Chưa xác thực");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
            }
            UserResponse res = userService.getOwnProfile(principal.getUser());
            return ResponseEntity.ok(res);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi lấy hồ sơ của bạn");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PatchMapping("/profile")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> updateProfile(@Valid @RequestBody UpdateUserProfileRequest request) {
        try {
            CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
            if (principal == null) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "Chưa xác thực");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
            }
            User updated = userService.updateProfile(principal.getUser(), request);
            UserResponse res = userService.getOwnProfile(updated);
            return ResponseEntity.ok(res);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi cập nhật hồ sơ");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @PostMapping("/avatar/upload-url")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> getAvatarUploadUrl(@Valid @RequestBody AvatarUploadRequest request) {
        try {
            CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
            if (principal == null) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "Chưa xác thực");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
            }
            AvatarUploadResponse resp = userService.generateAvatarUploadUrl(principal.getUser(), request.getFileName(), request.getContentType());
            return ResponseEntity.ok(resp);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Không thể tạo URL tải lên ảnh đại diện");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @DeleteMapping("/me")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> deleteOwnAccount(@Valid @RequestBody DeleteAccountRequest request) {
        try {
            CustomUserDetailsService.CustomUserPrincipal principal = getCurrentPrincipal();
            if (principal == null) {
                Map<String, String> error = new HashMap<>();
                error.put("error", "Chưa xác thực");
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
            }
            userService.deleteAccountWithOtp(principal.getUser(), request.getCode());
            Map<String, String> response = new HashMap<>();
            response.put("message", "Tài khoản đã được xóa thành công");
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi xóa tài khoản");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    @GetMapping("/search")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> searchUsers(@RequestParam(name = "q", required = false) String q) {
        try {
            List<PublicUserResponse> results = userService.search(q);
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi tìm kiếm người dùng");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }
}
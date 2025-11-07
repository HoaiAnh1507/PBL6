package com.pbl6.backend.controller;

import com.pbl6.backend.request.ForgotPasswordRequest;
import com.pbl6.backend.request.LoginRequest;
import com.pbl6.backend.request.ResetPasswordRequest;
import com.pbl6.backend.request.UserRegistrationRequest;
import com.pbl6.backend.response.AuthResponse;
import com.pbl6.backend.response.UserResponse;
import com.pbl6.backend.security.TokenBlacklistService;
import com.pbl6.backend.service.AuthService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*", maxAge = 3600)
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private TokenBlacklistService tokenBlacklistService;

    /**
     * API đăng ký người dùng mới
     * POST /api/auth/register
     * 
     * Flow theo sơ đồ use case:
     * 1. Nhận thông tin đăng ký
     * 2. Kiểm tra username/phone đã tồn tại
     * 3. Tạo tài khoản mới
     * 4. Trả về token và thông tin user
     */
    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody UserRegistrationRequest request) {
        try {
            AuthResponse response = authService.register(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("code", "REGISTRATION_FAILED");
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi trong quá trình đăng ký. Vui lòng thử lại!");
            error.put("code", "INTERNAL_ERROR");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * API đăng nhập
     * POST /api/auth/login
     * 
     * Hỗ trợ đăng nhập bằng EMAIL hoặc SỐ ĐIỆN THOẠI (KHÔNG hỗ trợ username)
     * 
     * Flow theo sơ đồ use case:
     * 1. Kiểm tra định dạng email hoặc số điện thoại
     * 2. Tìm tài khoản theo email/phone number
     * 3. Xác thực mật khẩu
     * 4. Kiểm tra trạng thái tài khoản
     * 5. Tạo JWT token
     * 6. Trả về thông tin đăng nhập
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            error.put("code", "LOGIN_FAILED");
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi trong quá trình đăng nhập. Vui lòng thử lại!");
            error.put("code", "INTERNAL_ERROR");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * API kiểm tra tính khả dụng của email
     * GET /api/auth/check-email?email=example@email.com
     * 
     * Hỗ trợ validation real-time trong form đăng ký
     */
    @GetMapping("/check-email")
    public ResponseEntity<Map<String, Object>> checkEmailAvailability(@RequestParam String email) {
        try {
            boolean isAvailable = authService.isEmailAvailable(email);
            Map<String, Object> response = new HashMap<>();
            response.put("available", isAvailable);
            response.put("email", email);
            
            if (!isAvailable) {
                response.put("message", "Email đã được sử dụng");
            } else {
                response.put("message", "Email khả dụng");
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("available", false);
            response.put("error", "Không thể kiểm tra email");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * API kiểm tra tính khả dụng của số điện thoại
     * GET /api/auth/check-phone?phoneNumber=0123456789
     * 
     * Hỗ trợ validation real-time trong form đăng ký
     */
    @GetMapping("/check-phone")
    public ResponseEntity<Map<String, Object>> checkPhoneNumberAvailability(@RequestParam String phoneNumber) {
        try {
            boolean isAvailable = authService.isPhoneNumberAvailable(phoneNumber);
            Map<String, Object> response = new HashMap<>();
            response.put("available", isAvailable);
            response.put("phoneNumber", phoneNumber);
            
            if (!isAvailable) {
                response.put("message", "Số điện thoại đã được sử dụng");
            } else {
                response.put("message", "Số điện thoại khả dụng");
            }
            
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("available", false);
            response.put("error", "Không thể kiểm tra số điện thoại");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(response);
        }
    }

    /**
     * API đặt lại mật khẩu (yêu cầu Bearer Token)
     * POST /api/auth/reset-password
     * 
     * Flow:
     * 1. Xác thực Bearer Token
     * 2. Nhận username và password mới từ request body
     * 3. Đặt lại mật khẩu cho user
     * 
     * Yêu cầu: Bearer Token hợp lệ trong header Authorization
     */
    @PostMapping("/reset-password")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        try {
            authService.resetPassword(request.getUsername(), request.getPassword());
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "Đặt lại mật khẩu thành công!");
            return ResponseEntity.ok(response);
            
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi đặt lại mật khẩu");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * POST /api/auth/logout
     * Yêu cầu Bearer Token. Thêm token hiện tại vào blacklist để vô hiệu hóa.
     */
    @PostMapping("/logout")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> logout(HttpServletRequest request) {
        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            String token = header.substring(7);
            tokenBlacklistService.blacklist(token);
        }
        Map<String, String> response = new HashMap<>();
        response.put("message", "Đăng xuất thành công");
        return ResponseEntity.ok(response);
    }

    /**
     * POST /api/auth/forgot-password (public)
     * Nhận email hoặc số điện thoại, kiểm tra tồn tại và khởi tạo quy trình.
     */
    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@Valid @RequestBody ForgotPasswordRequest request) {
        try {
            authService.initiateForgotPassword(request.getEmail_or_phonenumber());
            Map<String, String> response = new HashMap<>();
            response.put("message", "Đã khởi tạo quy trình quên mật khẩu. Vui lòng kiểm tra email.");
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi xử lý quên mật khẩu");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }

    /**
     * API xác minh OTP theo email (public)
     * POST /api/auth/verify-otp
     */
    @PostMapping("/verify-otp")
    public ResponseEntity<?> verifyOtp(@Valid @RequestBody com.pbl6.backend.request.VerifyOtpRequest request) {
        try {
            boolean ok = authService.verifyOtp(request.getEmail(), request.getCode());
            Map<String, Object> response = new HashMap<>();
            response.put("valid", ok);
            if (ok) {
                response.put("message", "OTP hợp lệ");
                return ResponseEntity.ok(response);
            } else {
                response.put("message", "OTP không hợp lệ hoặc đã hết hạn");
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
        } catch (RuntimeException e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.badRequest().body(error);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Đã xảy ra lỗi khi xác minh OTP");
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }



    /**
     * API lấy thông tin user hiện tại từ token
     * GET /api/auth/me
     * 
     * Yêu cầu Authorization header với Bearer token
     */
    @GetMapping("/me")
    @PreAuthorize("hasRole('USER') or hasRole('ADMIN')")
    public ResponseEntity<?> getCurrentUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated()) {
            Map<String, String> error = new HashMap<>();
            error.put("error", "Chưa xác thực");
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }
        Object principal = authentication.getPrincipal();
        if (principal instanceof com.pbl6.backend.security.CustomUserDetailsService.CustomUserPrincipal userPrincipal) {
            UserResponse userResponse = authService.toUserResponse(userPrincipal.getUser());
            return ResponseEntity.ok(userResponse);
        }
        Map<String, String> error = new HashMap<>();
        error.put("error", "Không thể lấy thông tin người dùng");
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
    }
}
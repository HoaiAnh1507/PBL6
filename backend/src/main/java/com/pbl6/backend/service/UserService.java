package com.pbl6.backend.service;

import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.request.UpdateUserProfileRequest;
import com.pbl6.backend.response.AvatarUploadResponse;
import com.pbl6.backend.response.PublicUserResponse;
import com.pbl6.backend.response.UserResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.regex.Pattern;

@Service
public class UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private AuthService authService;

    @Autowired
    private OtpService otpService;

    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    );

    public PublicUserResponse toPublicUserResponse(User user) {
        PublicUserResponse res = new PublicUserResponse();
        res.setUserId(user.getUserId());
        res.setUsername(user.getUsername());
        res.setFullName(user.getFullName());
        res.setProfilePictureUrl(user.getProfilePictureUrl());
        res.setCreatedAt(user.getCreatedAt());
        return res;
    }

    public Optional<User> findActiveById(String id) {
        return userRepository.findById(id).filter(u -> u.getAccountStatus() == User.AccountStatus.ACTIVE);
    }

    public UserResponse getOwnProfile(User currentUser) {
        return authService.toUserResponse(currentUser);
    }

    public User updateProfile(User currentUser, UpdateUserProfileRequest req) {
        if (req.getFullName() != null && !req.getFullName().isBlank()) {
            currentUser.setFullName(req.getFullName());
        }

        if (req.getPhoneNumber() != null && !req.getPhoneNumber().isBlank()) {
            String newPhone = req.getPhoneNumber();
            if (!newPhone.matches("^[+]?[0-9]{10,15}$")) {
                throw new RuntimeException("Số điện thoại không hợp lệ!");
            }
            if (!newPhone.equals(currentUser.getPhoneNumber()) && userRepository.existsByPhoneNumber(newPhone)) {
                throw new RuntimeException("Số điện thoại đã được sử dụng!");
            }
            currentUser.setPhoneNumber(newPhone);
        }

        if (req.getEmail() != null && !req.getEmail().isBlank()) {
            String newEmail = req.getEmail();
            if (!EMAIL_PATTERN.matcher(newEmail).matches()) {
                throw new RuntimeException("Email không hợp lệ!");
            }
            if (!newEmail.equals(currentUser.getEmail()) && userRepository.existsByEmail(newEmail)) {
                throw new RuntimeException("Email đã được sử dụng!");
            }
            currentUser.setEmail(newEmail);
        }

        if (req.getProfilePictureUrl() != null && !req.getProfilePictureUrl().isBlank()) {
            currentUser.setProfilePictureUrl(req.getProfilePictureUrl());
        }

        return userRepository.save(currentUser);
    }

    public AvatarUploadResponse generateAvatarUploadUrl(User currentUser, String fileName, String contentType) {
        // Stub pre-signed URL generation. Replace with real cloud storage integration later.
        String sanitizedFileName = UUID.randomUUID() + "_" + fileName.replaceAll("[^A-Za-z0-9._-]", "_");
        String fileKey = "avatars/" + currentUser.getUserId() + "/" + sanitizedFileName;
        long ttlSeconds = 300L;
        long expiresAt = Instant.now().getEpochSecond() + ttlSeconds;
        String uploadUrl = "https://storage.local/upload/" + fileKey + "?expires=" + expiresAt;

        AvatarUploadResponse resp = new AvatarUploadResponse();
        resp.setUploadUrl(uploadUrl);
        resp.setFileKey(fileKey);
        resp.setMethod("PUT");
        resp.setExpiresIn(ttlSeconds);
        Map<String, String> headers = new HashMap<>();
        headers.put("Content-Type", contentType);
        resp.setHeaders(headers);
        return resp;
    }

    public void deleteAccountWithOtp(User currentUser, String code) {
        String email = currentUser.getEmail();
        if (email == null || email.isBlank()) {
            throw new RuntimeException("Tài khoản không có email để xác thực OTP");
        }
        boolean ok = otpService.verifyOtp(email, code);
        if (!ok) {
            throw new RuntimeException("Mã OTP không hợp lệ hoặc đã hết hạn");
        }
        userRepository.delete(currentUser);
    }

    public List<PublicUserResponse> search(String q) {
        if (q == null || q.isBlank()) {
            return Collections.emptyList();
        }
        List<User> users = userRepository.searchByKeyword(q);
        List<PublicUserResponse> res = new ArrayList<>();
        for (User u : users) {
            if (u.getAccountStatus() == User.AccountStatus.ACTIVE) {
                res.add(toPublicUserResponse(u));
            }
        }
        return res;
    }
}
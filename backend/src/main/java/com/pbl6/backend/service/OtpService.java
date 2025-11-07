package com.pbl6.backend.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.regex.Pattern;

@Service
public class OtpService {

    private final Map<String, OtpRecord> otpStore = new ConcurrentHashMap<>();
    private final Map<String, Instant> lastSent = new ConcurrentHashMap<>();

    private final SecureRandom random = new SecureRandom();

    private static final Pattern EMAIL_PATTERN = Pattern.compile(
            "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    );

    @Value("${otp.ttl.seconds:300}")
    private long ttlSeconds;

    @Value("${otp.resend.cooldown.seconds:60}")
    private long resendCooldownSeconds;

    @Value("${otp.max-attempts:5}")
    private int maxAttempts;

    @Autowired
    private EmailService emailService;

    public void sendOtp(String identifier) {
        boolean isEmail = EMAIL_PATTERN.matcher(identifier).matches();
        if (!isEmail) {
            throw new RuntimeException("Vui lòng nhập email hợp lệ");
        }

        Instant now = Instant.now();
        Instant last = lastSent.get(identifier);
        if (last != null && Duration.between(last, now).getSeconds() < resendCooldownSeconds) {
            long wait = resendCooldownSeconds - Duration.between(last, now).getSeconds();
            throw new RuntimeException("Vui lòng chờ " + wait + "s trước khi yêu cầu lại OTP");
        }

        String code = String.format("%06d", random.nextInt(1_000_000));
        OtpRecord record = new OtpRecord(code, now.plusSeconds(ttlSeconds), 0);
        otpStore.put(identifier, record);
        lastSent.put(identifier, now);

        try {
            emailService.sendOtpEmail(identifier, code);
        } catch (Exception e) {
            throw new RuntimeException("Không thể gửi OTP: " + e.getMessage());
        }
    }

    public boolean verifyOtp(String identifier, String code) {
        OtpRecord record = otpStore.get(identifier);
        if (record == null) return false;
        if (Instant.now().isAfter(record.expiresAt())) {
            otpStore.remove(identifier);
            return false;
        }
        if (!record.code().equals(code)) {
            int attempts = record.attempts() + 1;
            if (attempts >= maxAttempts) {
                otpStore.remove(identifier);
            } else {
                otpStore.put(identifier, new OtpRecord(record.code(), record.expiresAt(), attempts));
            }
            return false;
        }
        // Success
        otpStore.remove(identifier);
        return true;
    }

    private record OtpRecord(String code, Instant expiresAt, int attempts) {}
}
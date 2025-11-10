package com.pbl6.backend.service;

import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.request.LoginRequest;
import com.pbl6.backend.request.UserRegistrationRequest;
import com.pbl6.backend.response.AuthResponse;
import com.pbl6.backend.response.UserResponse;
import com.pbl6.backend.security.JwtUtil;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;
import java.util.regex.Pattern;

@Service
@Transactional
public class AuthService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private OtpService otpService;

    // Email validation pattern
    private static final Pattern EMAIL_PATTERN = Pattern.compile(
        "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
    );

    /**
     * Đăng ký người dùng mới
     */
    public AuthResponse register(UserRegistrationRequest request) {
        // Kiểm tra username đã tồn tại
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Username đã tồn tại!");
        }

        // Kiểm tra số điện thoại đã tồn tại
        if (userRepository.existsByPhoneNumber(request.getPhoneNumber())) {
            throw new RuntimeException("Số điện thoại đã được sử dụng!");
        }

        // Validate password strength
        validatePassword(request.getPassword());

        // Tạo user mới
        User user = new User();
        user.setUsername(request.getUsername());
        user.setFullName(request.getFullName());
        user.setPhoneNumber(request.getPhoneNumber());
        user.setEmail(request.getEmail());
        user.setPasswordHash(passwordEncoder.encode(request.getPassword()));
        user.setAccountStatus(User.AccountStatus.ACTIVE);
        user.setSubscriptionStatus(User.SubscriptionStatus.FREE);

        // Lưu user vào database
        User savedUser = userRepository.save(user);

        // Tạo JWT token với subject là email (ưu tiên) hoặc phone number để đồng bộ với cơ chế đăng nhập
        String subject = (savedUser.getEmail() != null && !savedUser.getEmail().isBlank())
            ? savedUser.getEmail()
            : savedUser.getPhoneNumber();
        String token = jwtUtil.generateToken(subject);

        // Tạo UserResponse
        UserResponse userResponse = convertToUserResponse(savedUser);

        return new AuthResponse(token, userResponse, "Đăng ký thành công!");
    }

    /**
     * Đăng nhập người dùng
     * Hỗ trợ đăng nhập bằng email hoặc số điện thoại (không hỗ trợ username)
     */
    public AuthResponse login(LoginRequest request) {
        try {
            // Lấy thông tin đăng nhập (email hoặc phone number)
            String loginIdentifier = request.getEmail_or_phonenumber();
            User user = null;

            // Kiểm tra định dạng để xác định email hoặc phone number
            if (EMAIL_PATTERN.matcher(loginIdentifier).matches()) {
                // Tìm user bằng email  
                Optional<User> userOptional = userRepository.findByEmail(loginIdentifier);
                if (userOptional.isEmpty()) {
                    throw new RuntimeException("Email không tồn tại trong hệ thống!");
                }
                user = userOptional.get();
            } else {
                // Kiểm tra định dạng số điện thoại (chỉ chứa số và có thể bắt đầu bằng +)
                if (!loginIdentifier.matches("^[+]?[0-9]{10,15}$")) {
                    throw new RuntimeException("Định dạng email hoặc số điện thoại không hợp lệ!");
                }
                // Tìm user bằng số điện thoại
                Optional<User> userOptional = userRepository.findByPhoneNumber(loginIdentifier);
                if (userOptional.isEmpty()) {
                    throw new RuntimeException("Số điện thoại không tồn tại trong hệ thống!");
                }
                user = userOptional.get();
            }

            // Kiểm tra trạng thái tài khoản
            if (user.getAccountStatus() != User.AccountStatus.ACTIVE) {
                throw new RuntimeException("Tài khoản đã bị khóa hoặc vô hiệu hóa!");
            }

            // Xác thực mật khẩu - sử dụng loginIdentifier thay vì username
            Authentication authentication = authenticationManager.authenticate(
                new UsernamePasswordAuthenticationToken(
                    loginIdentifier, // Sử dụng email hoặc phone number để authenticate
                    request.getPassword()
                )
            );

            // Tạo JWT token với loginIdentifier
            String token = jwtUtil.generateToken(loginIdentifier);

            // Tạo UserResponse
            UserResponse userResponse = convertToUserResponse(user);

            return new AuthResponse(token, userResponse, "Đăng nhập thành công!");

        } catch (BadCredentialsException e) {
            throw new RuntimeException("Mật khẩu không đúng!");
        } catch (Exception e) {
            if (e.getMessage().contains("không tồn tại") || e.getMessage().contains("bị khóa") || 
                e.getMessage().contains("không hợp lệ")) {
                throw e;
            }
            throw new RuntimeException("Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin!");
        }
    }

    /**
     * Kiểm tra tính khả dụng của username
     */
    public boolean isUsernameAvailable(String username) {
        return !userRepository.existsByUsername(username);
    }

    /**
     * Kiểm tra tính khả dụng của số điện thoại
     */
    public boolean isPhoneNumberAvailable(String phoneNumber) {
        return !userRepository.existsByPhoneNumber(phoneNumber);
    }

    /**
     * Kiểm tra tính khả dụng của email
     */
    public boolean isEmailAvailable(String email) {
        return !userRepository.existsByEmail(email);
    }

    /**
     * Đặt lại mật khẩu (chức năng quên mật khẩu)
     */
    public void resetPassword(String username, String newPassword) {
        Optional<User> userOptional = userRepository.findByUsername(username);
        if (userOptional.isEmpty()) {
            throw new RuntimeException("Không tìm thấy người dùng!");
        }

        User user = userOptional.get();
        validatePassword(newPassword);
        
        user.setPasswordHash(passwordEncoder.encode(newPassword));
        userRepository.save(user);
    }

    /**
     * Khởi tạo quy trình quên mật khẩu: kiểm tra tồn tại email/phone và giả lập gửi mã/đường dẫn.
     */
    public void initiateForgotPassword(String identifier) {
        boolean isEmail = EMAIL_PATTERN.matcher(identifier).matches();
        if (!isEmail) {
            throw new RuntimeException("Vui lòng nhập email hợp lệ");
        }

        boolean exists = userRepository.existsByEmail(identifier);
        if (!exists) {
            throw new RuntimeException("Không tìm thấy tài khoản tương ứng với email này");
        }

        // Gửi OTP thật qua email
        otpService.sendOtp(identifier);
    }

    /**
     * Xác minh OTP theo email
     */
    public boolean verifyOtp(String email, String code) {
        boolean isEmail = EMAIL_PATTERN.matcher(email).matches();
        if (!isEmail) {
            throw new RuntimeException("Vui lòng nhập email hợp lệ");
        }
        boolean exists = userRepository.existsByEmail(email);
        if (!exists) {
            throw new RuntimeException("Không tìm thấy tài khoản tương ứng với email này");
        }
        return otpService.verifyOtp(email, code);
    }

    /**
     * Public helper để chuyển User sang UserResponse cho controller.
     */
    public UserResponse toUserResponse(User user) {
        return convertToUserResponse(user);
    }

    /**
     * Xác thực tài khoản qua email (nếu cần implement sau)
     */
    public void verifyAccount(String username, String verificationCode) {
        // TODO: Implement email verification logic
        Optional<User> userOptional = userRepository.findByUsername(username);
        if (userOptional.isEmpty()) {
            throw new RuntimeException("Không tìm thấy người dùng!");
        }

        User user = userOptional.get();
        // Verify code logic here
        user.setAccountStatus(User.AccountStatus.ACTIVE);
        userRepository.save(user);
    }

    /**
     * Validate password strength
     */
    private void validatePassword(String password) {
        if (password.length() < 6) {
            throw new RuntimeException("Mật khẩu phải có ít nhất 6 ký tự!");
        }
        
        // Có thể thêm các rule khác như:
        // - Phải có ít nhất 1 chữ hoa
        // - Phải có ít nhất 1 số
        // - Phải có ít nhất 1 ký tự đặc biệt
        
        boolean hasUpperCase = password.chars().anyMatch(Character::isUpperCase);
        boolean hasLowerCase = password.chars().anyMatch(Character::isLowerCase);
        boolean hasDigit = password.chars().anyMatch(Character::isDigit);
        
        if (!hasUpperCase || !hasLowerCase || !hasDigit) {
            throw new RuntimeException(
                "Mật khẩu không hợp lệ. Yêu cầu:\n" +
                "- Ít nhất 1 chữ hoa.\n" +
                "- Ít nhất 1 chữ thường.\n" +
                "- Ít nhất 1 chữ số."
            );
        }
    }

    /**
     * Chuyển đổi User entity thành UserResponse
     */
    private UserResponse convertToUserResponse(User user) {
        UserResponse userResponse = new UserResponse();
        userResponse.setUserId(user.getUserId());
        userResponse.setUsername(user.getUsername());
        userResponse.setFullName(user.getFullName());
        userResponse.setPhoneNumber(user.getPhoneNumber());
        userResponse.setEmail(user.getEmail());
        userResponse.setBio(null); // User model chưa có trường bio
        userResponse.setProfilePictureUrl(user.getProfilePictureUrl());
        userResponse.setAccountStatus(user.getAccountStatus().toString());
        userResponse.setSubscriptionPlan(user.getSubscriptionStatus().toString());
        userResponse.setCreatedAt(user.getCreatedAt());
        return userResponse;
    }
}
package com.pbl6.backend.service;

import com.pbl6.backend.model.User;
import com.pbl6.backend.repository.UserRepository;
import com.pbl6.backend.request.UpdateUserProfileRequest;
import com.pbl6.backend.response.PublicUserResponse;
import com.pbl6.backend.response.UserResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

/**
 * Unit Test cho UserService
 * Test business logic với Mock dependencies
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("User Service Tests")
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private AuthService authService;

    @Mock
    private OtpService otpService;

    @InjectMocks
    private UserService userService;

    private User testUser;

    @BeforeEach
    void setUp() {
        testUser = new User();
        testUser.setUserId("duy-uuid-123");
        testUser.setUsername("tranducduy");
        testUser.setEmail("tranducuduy739@gmail.com");
        testUser.setPhoneNumber("0905227016");
        testUser.setFullName("Trần Đức Duy");
        testUser.setPasswordHash("$2a$10$hashedPassword0905227016Duy");
        testUser.setAccountStatus(User.AccountStatus.ACTIVE);
        testUser.setSubscriptionStatus(User.SubscriptionStatus.FREE);
        testUser.setCreatedAt(LocalDateTime.now());
    }

    // ==================== Test 1: toPublicUserResponse ====================
    @Test
    @DisplayName("Test 1: Chuyển đổi User thành PublicUserResponse")
    void whenToPublicUserResponse_thenReturnCorrectResponse() {
        // ACT
        PublicUserResponse response = userService.toPublicUserResponse(testUser);

        // ASSERT
        assertThat(response).isNotNull();
        assertThat(response.getUserId()).isEqualTo("duy-uuid-123");
        assertThat(response.getUsername()).isEqualTo("tranducduy");
        assertThat(response.getFullName()).isEqualTo("Trần Đức Duy");
        assertThat(response.getCreatedAt()).isNotNull();
    }

    // ==================== Test 2: findActiveById ====================
    @Test
    @DisplayName("Test 2: Tìm user ACTIVE theo ID - thành công")
    void whenFindActiveById_thenReturnActiveUser() {
        // ARRANGE
        when(userRepository.findById("duy-uuid-123")).thenReturn(Optional.of(testUser));

        // ACT
        Optional<User> result = userService.findActiveById("duy-uuid-123");

        // ASSERT
        assertThat(result).isPresent();
        assertThat(result.get().getUserId()).isEqualTo("duy-uuid-123");
        assertThat(result.get().getAccountStatus()).isEqualTo(User.AccountStatus.ACTIVE);
        verify(userRepository, times(1)).findById("duy-uuid-123");
    }

    @Test
    @DisplayName("Test 2b: Tìm user INACTIVE theo ID - trả về empty")
    void whenFindActiveByIdButUserInactive_thenReturnEmpty() {
        // ARRANGE - User bị SUSPENDED
        testUser.setAccountStatus(User.AccountStatus.SUSPENDED);
        when(userRepository.findById("duy-uuid-123")).thenReturn(Optional.of(testUser));

        // ACT
        Optional<User> result = userService.findActiveById("duy-uuid-123");

        // ASSERT
        assertThat(result).isEmpty();
    }

    @Test
    @DisplayName("Test 2c: Tìm user không tồn tại - trả về empty")
    void whenFindActiveByIdNotFound_thenReturnEmpty() {
        // ARRANGE - ID sai (thêm chuỗi 'wrong')
        when(userRepository.findById("duy-uuid-123-wrong")).thenReturn(Optional.empty());

        // ACT
        Optional<User> result = userService.findActiveById("duy-uuid-123-wrong");

        // ASSERT
        assertThat(result).isEmpty();
    }

    // ==================== Test 3: getOwnProfile ====================
    @Test
    @DisplayName("Test 3: Lấy profile của user hiện tại")
    void whenGetOwnProfile_thenReturnUserResponse() {
        // ARRANGE
        UserResponse expectedResponse = new UserResponse();
        expectedResponse.setUserId("duy-uuid-123");
        expectedResponse.setUsername("tranducduy");
        expectedResponse.setEmail("tranducuduy739@gmail.com");

        when(authService.toUserResponse(testUser)).thenReturn(expectedResponse);

        // ACT
        UserResponse result = userService.getOwnProfile(testUser);

        // ASSERT
        assertThat(result).isNotNull();
        assertThat(result.getUserId()).isEqualTo("duy-uuid-123");
        assertThat(result.getUsername()).isEqualTo("tranducduy");
        verify(authService, times(1)).toUserResponse(testUser);
    }

    // ==================== Test 4: updateProfile - Full Name ====================
    @Test
    @DisplayName("Test 4: Cập nhật Full Name - thành công")
    void whenUpdateProfileWithFullName_thenUpdateSuccessfully() {
        // ARRANGE
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setFullName("Trần Đức Duy (Updated)");

        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // ACT
        User result = userService.updateProfile(testUser, request);

        // ASSERT
        assertThat(result.getFullName()).isEqualTo("Trần Đức Duy (Updated)");
        verify(userRepository, times(1)).save(testUser);
    }

    @Test
    @DisplayName("Test 4b: Cập nhật Full Name rỗng - không thay đổi")
    void whenUpdateProfileWithBlankFullName_thenNoChange() {
        // ARRANGE
        String originalName = testUser.getFullName();
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setFullName("   "); // blank

        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // ACT
        User result = userService.updateProfile(testUser, request);

        // ASSERT
        assertThat(result.getFullName()).isEqualTo(originalName);
    }

    // ==================== Test 5: updateProfile - Phone Number
    // ====================
    @Test
    @DisplayName("Test 5: Cập nhật số điện thoại hợp lệ - thành công")
    void whenUpdateProfileWithValidPhone_thenUpdateSuccessfully() {
        // ARRANGE - Đổi số mới (số của Nguyễn Hoài Anh)
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setPhoneNumber("0987654321");

        when(userRepository.existsByPhoneNumber("0987654321")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // ACT
        User result = userService.updateProfile(testUser, request);

        // ASSERT
        assertThat(result.getPhoneNumber()).isEqualTo("0987654321");
        verify(userRepository, times(1)).existsByPhoneNumber("0987654321");
        verify(userRepository, times(1)).save(testUser);
    }

    @Test
    @DisplayName("Test 5b: Cập nhật số điện thoại không hợp lệ - throw exception")
    void whenUpdateProfileWithInvalidPhone_thenThrowException() {
        // ARRANGE - Số điện thoại có chữ
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setPhoneNumber("090522abc16");

        // ACT & ASSERT
        assertThatThrownBy(() -> userService.updateProfile(testUser, request))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Số điện thoại không hợp lệ");

        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("Test 5c: Cập nhật số điện thoại đã tồn tại - throw exception")
    void whenUpdateProfileWithDuplicatePhone_thenThrowException() {
        // ARRANGE - Số đã được dùng bởi Nguyễn Hoài Anh
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setPhoneNumber("0123456789");

        when(userRepository.existsByPhoneNumber("0123456789")).thenReturn(true);

        // ACT & ASSERT
        assertThatThrownBy(() -> userService.updateProfile(testUser, request))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Số điện thoại đã được sử dụng");

        verify(userRepository, never()).save(any());
    }

    // ==================== Test 6: updateProfile - Email ====================
    @Test
    @DisplayName("Test 6: Cập nhật email hợp lệ - thành công")
    void whenUpdateProfileWithValidEmail_thenUpdateSuccessfully() {
        // ARRANGE - Email mới hợp lệ cho Duy
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setEmail("duytran.dev@gmail.com");

        when(userRepository.existsByEmail("duytran.dev@gmail.com")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // ACT
        User result = userService.updateProfile(testUser, request);

        // ASSERT
        assertThat(result.getEmail()).isEqualTo("duytran.dev@gmail.com");
        verify(userRepository, times(1)).existsByEmail("duytran.dev@gmail.com");
        verify(userRepository, times(1)).save(testUser);
    }

    @Test
    @DisplayName("Test 6b: Cập nhật email không hợp lệ - throw exception")
    void whenUpdateProfileWithInvalidEmail_thenThrowException() {
        // ARRANGE - Email thiếu @
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setEmail("tranducuduy739gmail.com");

        // ACT & ASSERT
        assertThatThrownBy(() -> userService.updateProfile(testUser, request))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Email không hợp lệ");

        verify(userRepository, never()).save(any());
    }

    @Test
    @DisplayName("Test 6c: Cập nhật email đã tồn tại - throw exception")
    void whenUpdateProfileWithDuplicateEmail_thenThrowException() {
        // ARRANGE - Email đã được dùng bởi Nguyễn Hoài Anh
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setEmail("anhnguyenhoai@gmail.com");

        when(userRepository.existsByEmail("anhnguyenhoai@gmail.com")).thenReturn(true);

        // ACT & ASSERT
        assertThatThrownBy(() -> userService.updateProfile(testUser, request))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Email đã được sử dụng");

        verify(userRepository, never()).save(any());
    }

    // ==================== Test 7: updateProfile - Profile Picture
    // ====================
    @Test
    @DisplayName("Test 7: Cập nhật profile picture URL - thành công")
    void whenUpdateProfileWithPictureUrl_thenUpdateSuccessfully() {
        // ARRANGE
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setProfilePictureUrl("https://storage.com/avatar.jpg");

        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // ACT
        User result = userService.updateProfile(testUser, request);

        // ASSERT
        assertThat(result.getProfilePictureUrl()).isEqualTo("https://storage.com/avatar.jpg");
        verify(userRepository, times(1)).save(testUser);
    }

    // ==================== Test 8: deleteAccountWithOtp ====================
    @Test
    @DisplayName("Test 8: Xóa tài khoản với OTP hợp lệ - thành công")
    void whenDeleteAccountWithValidOtp_thenDeleteSuccessfully() {
        // ARRANGE
        String otp = "123456";
        when(otpService.verifyOtp(testUser.getEmail(), otp)).thenReturn(true);

        // ACT
        userService.deleteAccountWithOtp(testUser, otp);

        // ASSERT
        verify(otpService, times(1)).verifyOtp(testUser.getEmail(), otp);
        verify(userRepository, times(1)).delete(testUser);
    }

    @Test
    @DisplayName("Test 8b: Xóa tài khoản với OTP không hợp lệ - throw exception")
    void whenDeleteAccountWithInvalidOtp_thenThrowException() {
        // ARRANGE
        String otp = "000000";
        when(otpService.verifyOtp(testUser.getEmail(), otp)).thenReturn(false);

        // ACT & ASSERT
        assertThatThrownBy(() -> userService.deleteAccountWithOtp(testUser, otp))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Mã OTP không hợp lệ hoặc đã hết hạn");

        verify(userRepository, never()).delete(any());
    }

    @Test
    @DisplayName("Test 8c: Xóa tài khoản không có email - throw exception")
    void whenDeleteAccountWithoutEmail_thenThrowException() {
        // ARRANGE
        testUser.setEmail(null);
        String otp = "123456";

        // ACT & ASSERT
        assertThatThrownBy(() -> userService.deleteAccountWithOtp(testUser, otp))
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("Tài khoản không có email");

        verify(otpService, never()).verifyOtp(anyString(), anyString());
        verify(userRepository, never()).delete(any());
    }

    // ==================== Test 9: search ====================
    @Test
    @DisplayName("Test 9: Tìm kiếm users theo keyword - trả về kết quả")
    void whenSearchWithKeyword_thenReturnUsers() {
        // ARRANGE - 2 thành viên nhóm
        User user1 = new User();
        user1.setUserId("duy-uuid-123");
        user1.setUsername("tranducduy");
        user1.setFullName("Trần Đức Duy");
        user1.setAccountStatus(User.AccountStatus.ACTIVE);
        user1.setCreatedAt(LocalDateTime.now());

        User user2 = new User();
        user2.setUserId("anh-uuid-456");
        user2.setUsername("nguyenhoaianh");
        user2.setFullName("Nguyễn Hoài Anh");
        user2.setAccountStatus(User.AccountStatus.ACTIVE);
        user2.setCreatedAt(LocalDateTime.now());

        when(userRepository.searchByKeyword("Duy")).thenReturn(Arrays.asList(user1));

        // ACT
        List<PublicUserResponse> results = userService.search("Duy");

        // ASSERT
        assertThat(results).hasSize(1);
        assertThat(results.get(0).getUsername()).isEqualTo("tranducduy");
        verify(userRepository, times(1)).searchByKeyword("Duy");
    }

    @Test
    @DisplayName("Test 9b: Tìm kiếm với keyword rỗng - trả về empty list")
    void whenSearchWithEmptyKeyword_thenReturnEmptyList() {
        // ACT
        List<PublicUserResponse> results = userService.search("");

        // ASSERT
        assertThat(results).isEmpty();
        verify(userRepository, never()).searchByKeyword(anyString());
    }

    @Test
    @DisplayName("Test 9c: Tìm kiếm với keyword null - trả về empty list")
    void whenSearchWithNullKeyword_thenReturnEmptyList() {
        // ACT
        List<PublicUserResponse> results = userService.search(null);

        // ASSERT
        assertThat(results).isEmpty();
        verify(userRepository, never()).searchByKeyword(anyString());
    }

    @Test
    @DisplayName("Test 9d: Tìm kiếm lọc bỏ users INACTIVE")
    void whenSearchWithInactiveUsers_thenFilterThem() {
        // ARRANGE
        User activeUser = new User();
        activeUser.setUserId("duy-uuid-123");
        activeUser.setUsername("tranducduy");
        activeUser.setFullName("Trần Đức Duy");
        activeUser.setAccountStatus(User.AccountStatus.ACTIVE);
        activeUser.setCreatedAt(LocalDateTime.now());

        User suspendedUser = new User();
        suspendedUser.setUserId("hieu-uuid-789");
        suspendedUser.setUsername("nguyenthanhhieu");
        suspendedUser.setFullName("Nguyễn Thành Hiếu");
        suspendedUser.setAccountStatus(User.AccountStatus.SUSPENDED);
        suspendedUser.setCreatedAt(LocalDateTime.now());

        when(userRepository.searchByKeyword("Nguyễn")).thenReturn(Arrays.asList(activeUser, suspendedUser));

        // ACT
        List<PublicUserResponse> results = userService.search("Nguyễn");

        // ASSERT - Chỉ trả về active user (filter out suspended)
        assertThat(results).hasSize(1);
        assertThat(results.get(0).getUsername()).isEqualTo("tranducduy");
    }

    // ==================== Test 10: Integration Test - Multiple Updates
    // ====================
    @Test
    @DisplayName("Test 10: Cập nhật nhiều trường cùng lúc - thành công")
    void whenUpdateMultipleFields_thenAllFieldsUpdated() {
        // ARRANGE
        UpdateUserProfileRequest request = new UpdateUserProfileRequest();
        request.setFullName("Trần Đức Duy (Pro Developer)");
        request.setEmail("duytran.work@gmail.com");
        request.setPhoneNumber("0905227099");
        request.setProfilePictureUrl("https://storage.pbl6.com/avatars/duy.jpg");

        when(userRepository.existsByEmail("duytran.work@gmail.com")).thenReturn(false);
        when(userRepository.existsByPhoneNumber("0905227099")).thenReturn(false);
        when(userRepository.save(any(User.class))).thenReturn(testUser);

        // ACT
        User result = userService.updateProfile(testUser, request);

        // ASSERT
        assertThat(result.getFullName()).isEqualTo("Trần Đức Duy (Pro Developer)");
        assertThat(result.getEmail()).isEqualTo("duytran.work@gmail.com");
        assertThat(result.getPhoneNumber()).isEqualTo("0905227099");
        assertThat(result.getProfilePictureUrl()).isEqualTo("https://storage.pbl6.com/avatars/duy.jpg");
        verify(userRepository, times(1)).save(testUser);
    }
}

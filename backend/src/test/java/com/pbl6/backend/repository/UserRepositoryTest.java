package com.pbl6.backend.repository;

import com.pbl6.backend.model.User;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.DisplayName;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.autoconfigure.orm.jpa.TestEntityManager;
import org.springframework.test.context.ActiveProfiles;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit Test cho UserRepository
 * Test các query methods và database operations
 */
@DataJpaTest
@ActiveProfiles("test")
@DisplayName("User Repository Tests")
class UserRepositoryTest {

    @Autowired
    private TestEntityManager entityManager;

    @Autowired
    private UserRepository userRepository;

    private User testUser1;
    private User testUser2;

    @BeforeEach
    void setUp() {
        // Xóa dữ liệu cũ
        userRepository.deleteAll();

        // User 1: Trần Đức Duy
        testUser1 = new User();
        testUser1.setUsername("tranducduy");
        testUser1.setEmail("tranducuduy739@gmail.com");
        testUser1.setPhoneNumber("0905227016");
        testUser1.setFullName("Trần Đức Duy");
        testUser1.setPasswordHash("$2a$10$hashedPassword0905227016Duy");
        testUser1.setAccountStatus(User.AccountStatus.ACTIVE);
        testUser1.setSubscriptionStatus(User.SubscriptionStatus.FREE);
        testUser1.setCreatedAt(LocalDateTime.now());

        // User 2: Nguyễn Hoài Anh
        testUser2 = new User();
        testUser2.setUsername("nguyenhoaianh");
        testUser2.setEmail("anhnguyenhoai@gmail.com");
        testUser2.setPhoneNumber("0706249288");
        testUser2.setFullName("Nguyễn Hoài Anh");
        testUser2.setPasswordHash("$2a$10$hashedPasswordNhanh204");
        testUser2.setAccountStatus(User.AccountStatus.ACTIVE);
        testUser2.setSubscriptionStatus(User.SubscriptionStatus.GOLD);
        testUser2.setCreatedAt(LocalDateTime.now());
    }

    // ==================== Test 1: findByUsername ====================
    @Test
    @DisplayName("Test 1: Tìm user theo username - thành công")
    void whenFindByUsername_thenReturnUser() {
        // ARRANGE - Lưu user vào DB
        entityManager.persist(testUser1);
        entityManager.flush();

        // ACT - Tìm user theo username
        Optional<User> found = userRepository.findByUsername("tranducduy");

        // ASSERT - Kiểm tra kết quả
        assertThat(found).isPresent();
        assertThat(found.get().getUsername()).isEqualTo("tranducduy");
        assertThat(found.get().getEmail()).isEqualTo("tranducuduy739@gmail.com");
        assertThat(found.get().getPhoneNumber()).isEqualTo("0905227016");
    }

    @Test
    @DisplayName("Test 1b: Tìm user theo username không tồn tại - trả về empty")
    void whenFindByUsernameNotExist_thenReturnEmpty() {
        // ACT - Tìm user không tồn tại (username sai)
        Optional<User> found = userRepository.findByUsername("tranducduy_sai");

        // ASSERT - Kiểm tra trả về empty
        assertThat(found).isEmpty();
    }

    // ==================== Test 2: findByEmail ====================
    @Test
    @DisplayName("Test 2: Tìm user theo email - thành công")
    void whenFindByEmail_thenReturnUser() {
        // ARRANGE
        entityManager.persist(testUser1);
        entityManager.flush();

        // ACT
        Optional<User> found = userRepository.findByEmail("tranducuduy739@gmail.com");

        // ASSERT
        assertThat(found).isPresent();
        assertThat(found.get().getEmail()).isEqualTo("tranducuduy739@gmail.com");
        assertThat(found.get().getUsername()).isEqualTo("tranducduy");
    }

    @Test
    @DisplayName("Test 2b: Tìm user theo email không tồn tại - trả về empty")
    void whenFindByEmailNotExist_thenReturnEmpty() {
        // ACT - Email sai (thêm số vào cuối)
        Optional<User> found = userRepository.findByEmail("tranducuduy739999@gmail.com");

        // ASSERT
        assertThat(found).isEmpty();
    }

    // ==================== Test 3: existsByUsername ====================
    @Test
    @DisplayName("Test 3: Kiểm tra username đã tồn tại - trả về true")
    void whenUsernameExists_thenReturnTrue() {
        // ARRANGE
        entityManager.persist(testUser1);
        entityManager.flush();

        // ACT
        boolean exists = userRepository.existsByUsername("tranducduy");

        // ASSERT
        assertThat(exists).isTrue();
    }

    @Test
    @DisplayName("Test 3b: Kiểm tra username không tồn tại - trả về false")
    void whenUsernameNotExists_thenReturnFalse() {
        // ACT - Username sai (viết hoa)
        boolean exists = userRepository.existsByUsername("TranDucDuy");

        // ASSERT
        assertThat(exists).isFalse();
    }

    // ==================== Test 4: existsByEmail ====================
    @Test
    @DisplayName("Test 4: Kiểm tra email đã tồn tại - trả về true")
    void whenEmailExists_thenReturnTrue() {
        // ARRANGE
        entityManager.persist(testUser1);
        entityManager.flush();

        // ACT
        boolean exists = userRepository.existsByEmail("tranducuduy739@gmail.com");

        // ASSERT
        assertThat(exists).isTrue();
    }

    @Test
    @DisplayName("Test 4b: Kiểm tra email không tồn tại - trả về false")
    void whenEmailNotExists_thenReturnFalse() {
        // ACT - Email sai (domain sai)
        boolean exists = userRepository.existsByEmail("tranducuduy739@yahoo.com");

        // ASSERT
        assertThat(exists).isFalse();
    }

    // ==================== Test 5: existsByPhoneNumber ====================
    @Test
    @DisplayName("Test 5: Kiểm tra số điện thoại đã tồn tại - trả về true")
    void whenPhoneNumberExists_thenReturnTrue() {
        // ARRANGE
        entityManager.persist(testUser1);
        entityManager.flush();

        // ACT
        boolean exists = userRepository.existsByPhoneNumber("0905227016");

        // ASSERT
        assertThat(exists).isTrue();
    }

    @Test
    @DisplayName("Test 5b: Kiểm tra số điện thoại không tồn tại - trả về false")
    void whenPhoneNumberNotExists_thenReturnFalse() {
        // ACT - Số điện thoại sai (đổi 1 chữ số)
        boolean exists = userRepository.existsByPhoneNumber("0905227017");

        // ASSERT
        assertThat(exists).isFalse();
    }

    // ==================== Test 6: findByAccountStatus ====================
    @Test
    @DisplayName("Test 6: Tìm tất cả users theo trạng thái tài khoản")
    void whenFindByAccountStatus_thenReturnUsers() {
        // ARRANGE - Lưu 2 users với trạng thái ACTIVE
        entityManager.persist(testUser1);
        entityManager.persist(testUser2);
        entityManager.flush();

        // ACT
        List<User> activeUsers = userRepository.findByAccountStatus(User.AccountStatus.ACTIVE);

        // ASSERT
        assertThat(activeUsers).hasSize(2);
        assertThat(activeUsers).extracting(User::getAccountStatus)
                .containsOnly(User.AccountStatus.ACTIVE);
    }

    // ==================== Test 7: findBySubscriptionStatus ====================
    @Test
    @DisplayName("Test 7: Tìm users theo loại subscription")
    void whenFindBySubscriptionStatus_thenReturnUsers() {
        // ARRANGE
        entityManager.persist(testUser1); // FREE - Trần Đức Duy
        entityManager.persist(testUser2); // PREMIUM - Nguyễn Hoài Anh
        entityManager.flush();

        // ACT
        List<User> premiumUsers = userRepository.findBySubscriptionStatus(User.SubscriptionStatus.GOLD);

        // ASSERT
        assertThat(premiumUsers).hasSize(1);
        assertThat(premiumUsers.get(0).getUsername()).isEqualTo("nguyenhoaianh");
        assertThat(premiumUsers.get(0).getSubscriptionStatus()).isEqualTo(User.SubscriptionStatus.GOLD);
    }

    // ==================== Test 8: searchByKeyword ====================
    @Test
    @DisplayName("Test 8: Tìm kiếm users theo từ khóa")
    void whenSearchByKeyword_thenReturnMatchingUsers() {
        // ARRANGE
        entityManager.persist(testUser1);
        entityManager.persist(testUser2);
        entityManager.flush();

        // ACT - Tìm theo keyword "Nguyễn" (có trong fullName của Nguyễn Hoài Anh)
        List<User> results = userRepository.searchByKeyword("Nguyễn");

        // ASSERT - Chỉ có Nguyễn Hoài Anh
        assertThat(results).hasSize(1);
        assertThat(results.get(0).getFullName()).contains("Nguyễn");
    }

    @Test
    @DisplayName("Test 8b: Tìm kiếm users theo email")
    void whenSearchByKeywordEmail_thenReturnMatchingUsers() {
        // ARRANGE
        entityManager.persist(testUser1);
        entityManager.persist(testUser2);
        entityManager.flush();

        // ACT - Tìm theo email của Trần Đức Duy
        List<User> results = userRepository.searchByKeyword("tranducuduy739@gmail.com");

        // ASSERT
        assertThat(results).hasSize(1);
        assertThat(results.get(0).getEmail()).isEqualTo("tranducuduy739@gmail.com");
    }

    // ==================== Test 9: countBySubscriptionStatus ====================
    @Test
    @DisplayName("Test 9: Đếm số lượng users theo subscription status")
    void whenCountBySubscriptionStatus_thenReturnCorrectCount() {
        // ARRANGE
        entityManager.persist(testUser1); // FREE
        entityManager.persist(testUser2); // PREMIUM
        entityManager.flush();

        // ACT
        long freeCount = userRepository.countBySubscriptionStatus(User.SubscriptionStatus.FREE);
        long premiumCount = userRepository.countBySubscriptionStatus(User.SubscriptionStatus.GOLD);

        // ASSERT
        assertThat(freeCount).isEqualTo(1);
        assertThat(premiumCount).isEqualTo(1);
    }

    // ==================== Test 10: Save và Update ====================
    @Test
    @DisplayName("Test 10: Lưu user mới vào database")
    void whenSaveUser_thenUserIsPersisted() {
        // ACT
        User saved = userRepository.save(testUser1);

        // ASSERT
        assertThat(saved.getUserId()).isNotNull();
        assertThat(saved.getUsername()).isEqualTo("tranducduy");

        // Verify trong DB
        User found = entityManager.find(User.class, saved.getUserId());
        assertThat(found).isNotNull();
        assertThat(found.getUsername()).isEqualTo("tranducduy");
        assertThat(found.getFullName()).isEqualTo("Trần Đức Duy");
    }

    @Test
    @DisplayName("Test 10b: Cập nhật thông tin user")
    void whenUpdateUser_thenUserIsUpdated() {
        // ARRANGE - Lưu user ban đầu
        entityManager.persist(testUser1);
        entityManager.flush();

        // ACT - Cập nhật thông tin (Duy đổi email sang email cá nhân khác)
        testUser1.setFullName("Trần Đức Duy (Updated)");
        testUser1.setEmail("duytran.dev@gmail.com");
        User updated = userRepository.save(testUser1);
        entityManager.flush(); // Force persistence

        // ASSERT
        assertThat(updated.getFullName()).isEqualTo("Trần Đức Duy (Updated)");
        assertThat(updated.getEmail()).isEqualTo("duytran.dev@gmail.com");

        // Verify trong DB
        entityManager.clear(); // Clear cache
        User found = entityManager.find(User.class, testUser1.getUserId());
        assertThat(found.getFullName()).isEqualTo("Trần Đức Duy (Updated)");
    }
}
